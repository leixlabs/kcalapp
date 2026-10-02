import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'calory.db');
    return openDatabase(
      path,
      version: 11,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE daily_goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        effective_date TEXT NOT NULL,
        kcal REAL NOT NULL,
        carbs_g REAL NOT NULL,
        protein_g REAL NOT NULL,
        fat_g REAL NOT NULL,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE meals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date_time TEXT NOT NULL,
        meal_type TEXT NOT NULL,
        name TEXT NOT NULL,
        photo_path TEXT,
        photo_asset_id TEXT,
        nutrition_review TEXT,
        servings REAL NOT NULL DEFAULT 1.0,
        source TEXT NOT NULL DEFAULT 'manual',
        ai_recognition_status TEXT NOT NULL DEFAULT 'none',
        is_deleted INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE food_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        meal_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        weight_g REAL NOT NULL,
        kcal REAL NOT NULL,
        carbs_g REAL NOT NULL,
        protein_g REAL NOT NULL,
        fat_g REAL NOT NULL,
        confidence TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        minerals_json TEXT,
        vitamins_json TEXT,
        category_id TEXT,
        FOREIGN KEY (meal_id) REFERENCES meals(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE llm_profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        display_name TEXT NOT NULL,
        base_url TEXT NOT NULL,
        model TEXT NOT NULL,
        timeout_seconds INTEGER NOT NULL DEFAULT 30,
        is_active INTEGER NOT NULL DEFAULT 0,
        use_json_mode INTEGER NOT NULL DEFAULT 1,
        response_format_mode INTEGER NOT NULL DEFAULT 2,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await _createMealReviewsTable(db);
    await _createWeeklyReviewsTable(db);

    await db.execute('CREATE INDEX idx_meals_date ON meals(date_time)');
    await db.execute('CREATE INDEX idx_meals_type ON meals(meal_type)');
    await db.execute('CREATE INDEX idx_food_items_meal ON food_items(meal_id)');
    await db.execute(
      'CREATE INDEX idx_daily_goals_date ON daily_goals(effective_date)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE llm_profiles ADD COLUMN use_json_mode INTEGER NOT NULL DEFAULT 1',
      );
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE food_items ADD COLUMN calcium_mg REAL');
      await db.execute('ALTER TABLE food_items ADD COLUMN sodium_mg REAL');
      await db.execute('ALTER TABLE food_items ADD COLUMN iron_mg REAL');
      await db.execute('ALTER TABLE food_items ADD COLUMN magnesium_mg REAL');
    }
    if (oldVersion < 4) {
      // 用两列 JSON 替代之前的散列列，旧数据不迁移（minerals/vitamins 为 null）
      await db.execute('ALTER TABLE food_items ADD COLUMN minerals_json TEXT');
      await db.execute('ALTER TABLE food_items ADD COLUMN vitamins_json TEXT');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE meals ADD COLUMN nutrition_review TEXT');
    }
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE food_items ADD COLUMN category_id TEXT');
    }
    if (oldVersion < 7) {
      await db.execute(
        'ALTER TABLE llm_profiles ADD COLUMN response_format_mode INTEGER NOT NULL DEFAULT 2',
      );
      await db.execute(
        'UPDATE llm_profiles SET response_format_mode = CASE WHEN use_json_mode = 1 THEN 2 ELSE 0 END',
      );
    }
    if (oldVersion < 8) {
      await db.execute(
        "ALTER TABLE meals ADD COLUMN ai_recognition_status TEXT NOT NULL DEFAULT 'none'",
      );
    }
    if (oldVersion < 9) {
      await _createMealReviewsTable(db);
    }
    if (oldVersion < 10) {
      await _createWeeklyReviewsTable(db);
    }
    if (oldVersion < 11) {
      // 照片改为存系统相册资源 id；photo_path 仅供旧记录回退。
      await db.execute('ALTER TABLE meals ADD COLUMN photo_asset_id TEXT');
    }
  }

  Future<void> _createMealReviewsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE meal_reviews (
        date TEXT NOT NULL,
        meal_type TEXT NOT NULL,
        content TEXT,
        status TEXT NOT NULL DEFAULT 'idle',
        updated_at TEXT NOT NULL DEFAULT (datetime('now')),
        PRIMARY KEY (date, meal_type)
      )
    ''');
  }

  Future<void> _createWeeklyReviewsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE weekly_reviews (
        week_start TEXT PRIMARY KEY,
        happened TEXT,
        improvement TEXT,
        signature TEXT NOT NULL DEFAULT '',
        updated_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Future<int> rawInsert(String sql, [List<Object?>? arguments]) async {
    final db = await database;
    return db.rawInsert(sql, arguments);
  }

  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    final db = await database;
    return db.rawQuery(sql, arguments);
  }

  Future<int> rawUpdate(String sql, [List<Object?>? arguments]) async {
    final db = await database;
    return db.rawUpdate(sql, arguments);
  }

  Future<int> rawDelete(String sql, [List<Object?>? arguments]) async {
    final db = await database;
    return db.rawDelete(sql, arguments);
  }

  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    final db = await database;
    await db.execute(sql, arguments);
  }

  // 注意：多语句写操作请直接使用 `await database` 拿到 sqflite Database 后
  // 调 db.transaction((tx) => ...)，并在回调内使用 tx（Transaction 对象）。
  // 不要在这里做丢弃 Transaction 的包装——回调内若回头调 Database 会死锁。
}
