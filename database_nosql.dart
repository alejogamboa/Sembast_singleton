import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:async/async.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:tribu/modelo/Envases.dart';
import 'package:tribu/modelo/indicadores_usuario.dart';
import 'package:tribu/modelo/ubicacion.dart';
import 'package:tribu/modelo/usuario.dart';

class TribuDatabaseNoSQL {
  // Singleton pattern
  static final TribuDatabaseNoSQL _dbManager =
      new TribuDatabaseNoSQL._internal();
  TribuDatabaseNoSQL._internal();
  static TribuDatabaseNoSQL get instance => _dbManager;

  // Members
  static Database? _db;
  final _initDBMemoizer = AsyncMemoizer<Database>();

  factory TribuDatabaseNoSQL() {
    return _dbManager;
  }

  Future<Database> reopenDatabase() {
    return _initDB();
  }

  Future<Database> get database async {
    if (_db != null) {
      return _db!;
    }
    // if _database is null we instantiate it
    _db = await _initDBMemoizer.runOnce(() async {
      return await _initDB();
    });
    return _db!;
  }

  Future<Database> _initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    await documentsDirectory.create(recursive: true);
    String path = join(documentsDirectory.path, "kaptar_nosql.db");
    _db = await databaseFactoryIo.openDatabase(path).catchError((error) {
      print("error en la base de datos " + error.toString());
      return throw Exception(error);
    });
    return _db!;
  }

  Future<List<Envases>> getEnvases() async {
    var storeEnvases = intMapStoreFactory.store("Envases");
    var records = await storeEnvases.find(_db!);
    List<Envases> resultados = [];
    for (var itemEnvas in records) {
      resultados.add(Envases.fromMap(itemEnvas));
    }
    return resultados;
  }

  Future<Envases?> getEnvaseCodigo(String codigo) async {
    var storeEnvases = intMapStoreFactory.store("Envases");
    var record = await storeEnvases.find(_db!,
        finder: Finder(filter: Filter.equals('codigo', '$codigo')));

    return Envases.fromMap(record[0]);
  }

  Future<List<Envases?>> getEnvasesNombre(String nombre) async {
    var storeEnvases = intMapStoreFactory.store("Envases");

    nombre = nombre.toLowerCase();

    var finder = Finder(filter: Filter.matches('nombreFiltro', '$nombre'));
    var records = await storeEnvases.find(_db!, finder: finder);

    List<Envases?> resultados = [];
    for (var itemEnvas in records) {
      resultados.add(Envases.fromMap(itemEnvas));
    }
    return resultados;
  }

  Future updateEnvases(List<dynamic> envases) async {
    var storeEnvases = intMapStoreFactory.store("Envases");
    await _db!.transaction((txn) async {
      for (var envase in envases) {
        await storeEnvases.record(envase[Envases.db_id]).put(txn, envase);
      }
    }).catchError((onError) {
      print(onError);
    }).whenComplete(() {
      print("guardó Envases");
    });
  }

  /// Inserts or replaces the Usuario.
  Future<Usuario> updateUsuario(dynamic usuario) async {
    var storeUsuario = intMapStoreFactory.store(Usuario.nombreTabla);
    await _db!.transaction((txn) async {
      await storeUsuario.record(1).put(txn, usuario);
    }).catchError((onError) {
      print(onError);
    }).whenComplete(() {
      print("guardó Usuario");
    });
    return Usuario.fromMap(usuario);
  }

  Future<Usuario> getUsuario() async {
    var storeUsuario = intMapStoreFactory.store(Usuario.nombreTabla);
    var records = await storeUsuario.find(_db!);
    if (records.isEmpty) {
      return Usuario(
          uid: -1,
          id: '-1',
          nombresUsuario: 'Error en almacenamiento local.',
          email: '',
          token: '');
    }
    var usr = records[0];
    return Usuario.fromMap(usr);
  }

  Future<bool> clearAllData() async {
    bool isOk = true;
    await close();
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "kaptar_nosql.db");
    await databaseFactoryIo.deleteDatabase(path);
    _db = null;
    return isOk;
  }

  Future updateIndicadores(dynamic indicadores) async {
    if (_db == null) {
      return;
    }
    var storeBalance = intMapStoreFactory.store(Indicadores.nombreTabla);
    await _db!.transaction((txn) async {
      await storeBalance.record(1).put(txn, indicadores);
    }).catchError((onError) {
      print(onError);
    }).whenComplete(() {
      print("guardó Indicadores");
    });
  }

  Future<Indicadores?> getIndicadores() async {
    if (_db == null) {
      return Indicadores();
    }
    var storeCuponesCompra = intMapStoreFactory.store(Indicadores.nombreTabla);
    var records = await storeCuponesCompra.find(_db!);
    if (records.isEmpty) {
      return null;
    }
    return Indicadores.fromMap(records[0]);
  }

  Future<List<Ubicacion>> getUbicaciones() async {
    var storeUbicacion = intMapStoreFactory.store(Ubicacion.nombreTabla);
    var records = await storeUbicacion.find(_db!);
    List<Ubicacion> resultados = [];
    for (var itemUbicacion in records) {
      resultados.add(Ubicacion.fromMap(itemUbicacion));
    }
    return resultados;
  }

  ///////////////////////////////////////////////////////////////
  Future close() async {
    if (_db == null) {
      return;
    }
    return _db!.close();
  }
}
