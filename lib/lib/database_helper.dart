import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      // Verificar si estamos en una plataforma compatible
      if (kIsWeb) {
        throw UnsupportedError('SQLite no es compatible con web');
      }

      String path;
      
      if (Platform.isAndroid || Platform.isIOS) {
        // Para móviles
        path = join(await getDatabasesPath(), 'granizados.db');
      } else {
        // Para desktop, usar directorio temporal
        final directory = Directory.systemTemp;
        path = join(directory.path, 'granizados.db');
      }
      
      print('Inicializando base de datos en: $path');
      
      return await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE ventas_locales(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              sabor TEXT NOT NULL,
              cantidad INTEGER NOT NULL,
              precio_unitario INTEGER NOT NULL,
              total INTEGER NOT NULL,
              fecha TEXT NOT NULL,
              sincronizado INTEGER DEFAULT 0
            )
          ''');
          print('Tabla ventas_locales creada exitosamente');
        },
        onOpen: (db) {
          print('Base de datos abierta exitosamente');
        },
      );
    } catch (e) {
      print('Error inicializando base de datos: $e');
      
      // Fallback: usar base de datos en memoria
      print('Usando base de datos en memoria como fallback');
      return await openDatabase(
        ':memory:',
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE ventas_locales(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              sabor TEXT NOT NULL,
              cantidad INTEGER NOT NULL,
              precio_unitario INTEGER NOT NULL,
              total INTEGER NOT NULL,
              fecha TEXT NOT NULL,
              sincronizado INTEGER DEFAULT 0
            )
          ''');
        },
      );
    }
  }

  // Insertar venta local
  Future<int> insertVentaLocal(Map<String, dynamic> venta) async {
    try {
      final db = await database;
      venta['sincronizado'] = 0;
      final result = await db.insert('ventas_locales', venta);
      print('Venta insertada con ID: $result');
      return result;
    } catch (e) {
      print('Error insertando venta: $e');
      return -1;
    }
  }

  // Obtener todas las ventas locales
  Future<List<Map<String, dynamic>>> getVentasLocales() async {
    try {
      final db = await database;
      final result = await db.query('ventas_locales', orderBy: 'fecha DESC');
      print('Ventas obtenidas: ${result.length}');
      return result;
    } catch (e) {
      print('Error obteniendo ventas: $e');
      return [];
    }
  }

  // Obtener ventas no sincronizadas
  Future<List<Map<String, dynamic>>> getVentasNoSincronizadas() async {
    try {
      final db = await database;
      final result = await db.query(
        'ventas_locales',
        where: 'sincronizado = ?',
        whereArgs: [0],
        orderBy: 'fecha ASC',
      );
      print('Ventas no sincronizadas: ${result.length}');
      return result;
    } catch (e) {
      print('Error obteniendo ventas no sincronizadas: $e');
      return [];
    }
  }

  // Marcar venta como sincronizada
  Future<void> marcarVentaSincronizada(int id) async {
    try {
      final db = await database;
      await db.update(
        'ventas_locales',
        {'sincronizado': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
      print('Venta $id marcada como sincronizada');
    } catch (e) {
      print('Error marcando venta como sincronizada: $e');
    }
  }

  // Limpiar ventas sincronizadas antiguas
  Future<void> limpiarVentasSincronizadas() async {
    try {
      final db = await database;
      final fechaLimite = DateTime.now().subtract(const Duration(days: 30));
      final result = await db.delete(
        'ventas_locales',
        where: 'sincronizado = ? AND fecha < ?',
        whereArgs: [1, fechaLimite.toIso8601String()],
      );
      print('Ventas antiguas eliminadas: $result');
    } catch (e) {
      print('Error limpiando ventas sincronizadas: $e');
    }
  }

  // Cerrar base de datos
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}