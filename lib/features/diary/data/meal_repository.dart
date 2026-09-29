import 'meal_dao.dart';
import '../domain/meal.dart';
import '../../../data/llm/llm_schema.dart';

class MealRepository {
  final MealDao _dao;
  MealRepository(this._dao);

  Future<List<Meal>> getMealsByDate(DateTime date) => _dao.getMealsByDate(date);
  Future<List<Meal>> getMealsByMonth(DateTime month) =>
      _dao.getMealsByMonth(month);
  Future<List<Meal>> getMealsBetween(DateTime start, DateTime end) =>
      _dao.getMealsBetween(start, end);
  Future<List<Meal>> getAllMeals() => _dao.getAllMeals();
  Future<Meal?> getMealById(int id) => _dao.getMealById(id);
  Future<int> saveMeal(Meal meal) => _dao.saveMeal(meal);
  Future<void> updateMeal(Meal meal) => _dao.updateMeal(meal);
  Future<void> updateAiRecognition(
    int mealId, {
    required AiRecognitionStatus status,
    LlmRecognitionResult? result,
  }) => _dao.updateAiRecognition(mealId, status: status, result: result);
  Future<void> softDeleteMeal(int id) => _dao.softDeleteMeal(id);
  Future<void> restoreMeal(int id) => _dao.restoreMeal(id);
  Future<void> hardDeleteMeal(int id) => _dao.hardDeleteMeal(id);
}
