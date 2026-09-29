import '../../../data/database/database.dart';
import '../domain/food_item.dart';
import '../domain/meal.dart';
import '../domain/meal_type.dart';

class MealDao {
  final AppDatabase db;
  MealDao(this.db);

  Future<List<Meal>> getMealsByDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();

    final mealsRows = await db.rawQuery(
      'SELECT * FROM meals WHERE date_time >= ? AND date_time < ? AND is_deleted = 0 ORDER BY date_time',
      [startStr, endStr],
    );

    final List<Meal> result = [];
    for (final row in mealsRows) {
      final itemsRows = await db.rawQuery(
        'SELECT * FROM food_items WHERE meal_id = ? ORDER BY sort_order',
        [row['id']],
      );
      result.add(_toDomain(row, itemsRows));
    }
    return result;
  }

  Future<List<Meal>> getMealsByMonth(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();

    final mealsRows = await db.rawQuery(
      'SELECT * FROM meals WHERE date_time >= ? AND date_time < ? AND is_deleted = 0 ORDER BY date_time',
      [startStr, endStr],
    );

    final List<Meal> result = [];
    for (final row in mealsRows) {
      final itemsRows = await db.rawQuery(
        'SELECT * FROM food_items WHERE meal_id = ? ORDER BY sort_order',
        [row['id']],
      );
      result.add(_toDomain(row, itemsRows));
    }
    return result;
  }

  Future<List<Meal>> getAllMeals() async {
    final mealsRows = await db.rawQuery(
      'SELECT * FROM meals WHERE is_deleted = 0 ORDER BY date_time',
    );

    final List<Meal> result = [];
    for (final row in mealsRows) {
      final itemsRows = await db.rawQuery(
        'SELECT * FROM food_items WHERE meal_id = ? ORDER BY sort_order',
        [row['id']],
      );
      result.add(_toDomain(row, itemsRows));
    }
    return result;
  }

  Future<Meal?> getMealById(int id) async {
    final rows = await db.rawQuery('SELECT * FROM meals WHERE id = ?', [id]);
    if (rows.isEmpty) return null;
    final itemsRows = await db.rawQuery(
      'SELECT * FROM food_items WHERE meal_id = ? ORDER BY sort_order',
      [id],
    );
    return _toDomain(rows.first, itemsRows);
  }

  Future<int> saveMeal(Meal meal) async {
    final database = await db.database;
    return database.transaction((tx) async {
      final now = DateTime.now().toIso8601String();
      final mealId = await tx.rawInsert(
        'INSERT INTO meals (date_time, meal_type, name, photo_path, nutrition_review, servings, source, is_deleted, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, 0, ?, ?)',
        [
          meal.dateTime.toIso8601String(),
          meal.mealType.name,
          meal.name,
          meal.photoPath,
          meal.nutritionReview,
          meal.servings,
          meal.source,
          now,
          now,
        ],
      );

      for (var i = 0; i < meal.foodItems.length; i++) {
        final item = meal.foodItems[i];
        await tx.rawInsert(
          'INSERT INTO food_items (meal_id, name, weight_g, kcal, carbs_g, protein_g, fat_g, confidence, sort_order, minerals_json, vitamins_json) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            mealId,
            item.name,
            item.weightG,
            item.kcal,
            item.carbsG,
            item.proteinG,
            item.fatG,
            item.confidence?.name,
            i,
            MicronutrientList.toJson(item.minerals),
            MicronutrientList.toJson(item.vitamins),
          ],
        );
      }
      return mealId;
    });
  }

  Future<void> updateMeal(Meal meal) async {
    assert(meal.id != null);
    final database = await db.database;
    await database.transaction((tx) async {
      await tx.rawUpdate(
        'UPDATE meals SET date_time = ?, meal_type = ?, name = ?, photo_path = ?, nutrition_review = ?, servings = ?, updated_at = ? WHERE id = ?',
        [
          meal.dateTime.toIso8601String(),
          meal.mealType.name,
          meal.name,
          meal.photoPath,
          meal.nutritionReview,
          meal.servings,
          DateTime.now().toIso8601String(),
          meal.id,
        ],
      );
      await tx.rawDelete('DELETE FROM food_items WHERE meal_id = ?', [meal.id]);
      for (var i = 0; i < meal.foodItems.length; i++) {
        final item = meal.foodItems[i];
        await tx.rawInsert(
          'INSERT INTO food_items (meal_id, name, weight_g, kcal, carbs_g, protein_g, fat_g, confidence, sort_order, minerals_json, vitamins_json) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            meal.id,
            item.name,
            item.weightG,
            item.kcal,
            item.carbsG,
            item.proteinG,
            item.fatG,
            item.confidence?.name,
            i,
            MicronutrientList.toJson(item.minerals),
            MicronutrientList.toJson(item.vitamins),
          ],
        );
      }
    });
  }

  Future<void> softDeleteMeal(int id) async {
    await db.rawUpdate(
      'UPDATE meals SET is_deleted = 1, updated_at = ? WHERE id = ?',
      [DateTime.now().toIso8601String(), id],
    );
  }

  Future<void> restoreMeal(int id) async {
    await db.rawUpdate(
      'UPDATE meals SET is_deleted = 0, updated_at = ? WHERE id = ?',
      [DateTime.now().toIso8601String(), id],
    );
  }

  Future<void> hardDeleteMeal(int id) async {
    await db.rawDelete('DELETE FROM meals WHERE id = ?', [id]);
  }

  Meal _toDomain(Map<String, dynamic> row, List<Map<String, dynamic>> items) {
    return Meal(
      id: row['id'] as int?,
      dateTime: DateTime.parse(row['date_time'] as String),
      mealType: MealType.fromString(row['meal_type'] as String?),
      name: row['name'] as String? ?? '',
      photoPath: row['photo_path'] as String?,
      nutritionReview: row['nutrition_review'] as String?,
      servings: (row['servings'] as num?)?.toDouble() ?? 1.0,
      source: row['source'] as String? ?? 'manual',
      foodItems: items
          .map(
            (i) => FoodItem(
              id: i['id'] as int?,
              mealId: i['meal_id'] as int?,
              name: i['name'] as String? ?? '',
              weightG: (i['weight_g'] as num?)?.toDouble() ?? 0,
              kcal: (i['kcal'] as num?)?.toDouble() ?? 0,
              carbsG: (i['carbs_g'] as num?)?.toDouble() ?? 0,
              proteinG: (i['protein_g'] as num?)?.toDouble() ?? 0,
              fatG: (i['fat_g'] as num?)?.toDouble() ?? 0,
              confidence: FoodItem.parseConfidence(i['confidence'] as String?),
              sortOrder: i['sort_order'] as int? ?? 0,
              minerals: MicronutrientList.fromJson(
                i['minerals_json'] as String?,
                length: Mineral.values.length,
              ),
              vitamins: MicronutrientList.fromJson(
                i['vitamins_json'] as String?,
                length: Vitamin.values.length,
              ),
            ),
          )
          .toList(),
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}
