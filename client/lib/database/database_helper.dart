import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  static void init() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    init();
    
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'synapse.db');
    
    print('📁 Путь к БД: $path');
    
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    print('📁 Создаю базу данных...');
    
    // Таблица пользователей
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        avatar_color TEXT,
        avatar_path TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    
    // Таблица папок
    await db.execute('''
      CREATE TABLE folders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        parent_id INTEGER,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY(parent_id) REFERENCES folders(id) ON DELETE CASCADE
      )
    ''');
    
    // Таблица заметок
    await db.execute('''
      CREATE TABLE notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        folder_id INTEGER,
        title TEXT NOT NULL,
        content TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY(folder_id) REFERENCES folders(id) ON DELETE SET NULL
      )
    ''');
    
    // Таблица тегов
    await db.execute('''
      CREATE TABLE tags(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        color TEXT NOT NULL,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
        UNIQUE(user_id, name)
      )
    ''');
    
    // Таблица связей заметок с тегами
    await db.execute('''
      CREATE TABLE note_tags(
        note_id INTEGER NOT NULL,
        tag_id INTEGER NOT NULL,
        FOREIGN KEY(note_id) REFERENCES notes(id) ON DELETE CASCADE,
        FOREIGN KEY(tag_id) REFERENCES tags(id) ON DELETE CASCADE,
        PRIMARY KEY(note_id, tag_id)
      )
    ''');
    
    // Таблица изображений заметок
    await db.execute('''
      CREATE TABLE note_images(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        note_id INTEGER NOT NULL,
        image_path TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY(note_id) REFERENCES notes(id) ON DELETE CASCADE
      )
    ''');
    
    // Таблица связей между заметками (для графа)
    await db.execute('''
      CREATE TABLE note_links(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        source_note_id INTEGER NOT NULL,
        target_note_id INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY(source_note_id) REFERENCES notes(id) ON DELETE CASCADE,
        FOREIGN KEY(target_note_id) REFERENCES notes(id) ON DELETE CASCADE,
        UNIQUE(source_note_id, target_note_id)
      )
    ''');
    
    // Создаем тестового пользователя
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert('users', {
      'username': 'demo',
      'email': 'demo@example.com',
      'password': 'demo123',
      'avatar_color': '#8B7EF6',
      'avatar_path': null,
      'created_at': now,
      'updated_at': now,
    });
    
    // Создаем корневую папку для тестового пользователя
    final user = await db.query('users', where: 'username = ?', whereArgs: ['demo']);
    final userId = user.first['id'];
    
    await db.insert('folders', {
      'user_id': userId,
      'parent_id': null,
      'name': 'Мои заметки',
      'created_at': now,
      'updated_at': now,
    });
    
    print('✅ База данных создана, тестовый пользователь добавлен');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('📁 Обновляю базу данных с версии $oldVersion до $newVersion...');
    
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS note_links(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          source_note_id INTEGER NOT NULL,
          target_note_id INTEGER NOT NULL,
          created_at INTEGER NOT NULL,
          FOREIGN KEY(source_note_id) REFERENCES notes(id) ON DELETE CASCADE,
          FOREIGN KEY(target_note_id) REFERENCES notes(id) ON DELETE CASCADE,
          UNIQUE(source_note_id, target_note_id)
        )
      ''');
      print('✅ Таблица note_links добавлена');
    }
  }
}