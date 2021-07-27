///API untuk FileManagerApp, fungsi : menyimpan, mengubah nama, memindahkan dan menghapus file, serta memberi
///data isi dari sebuah directory dan data file
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:file_manager_app/ServerSideAPI/database.dart';
import 'package:mime/mime.dart';

Future<void> main() async {
  //create server
  HttpServer server;
  try {
    server = await createServer();
  } catch (error) {
    return;
  }

  //create root directory for saving files if does not exist yet
  if (!Directory('root').existsSync()) {
    Directory('root').createSync();
  }

  //listen for upcoming request
  server.listen(
    (request) async {
      /// Terkadang data besar yg terkirim dibagi jadi beberapa bagian yg dikirim terpisah
      /// setiap byte data yang dikirim akan disimpan di requestData
      List<int> requestData = [];
      request.listen(
        (dataBytes) {
          requestData.addAll(dataBytes);
        },
        onDone: () async {
          final response = request.response;
          // allowing to send response across different address
          response.headers.add("Access-Control-Allow-Origin", '*');

          if (request.uri.hasQuery) {
            final query = request.uri.queryParameters;
            switch (query['requestType']) {
              case 'viewFile':
                await viewFile(
                  response: response,
                  path: query['path'],
                );
                break;
              case 'upload':
                if (requestData.isEmpty) {
                  // if there have been error in sending requestDta, tell the client to retry
                  response.statusCode = 503;
                } else {
                  await createFileByte(
                    response: response,
                    path: query['path'],
                    data: requestData,
                  );
                }
                break;
              case 'download':
                await downloadFile(response: response, path: query['path']);
            }
          } else if (request.method == 'POST') {
            /// menyimpan dataRequest yang telah di-decode
            Map requestInfo;
            try {
              //jika ada masalah saat pengiriman data, data mungkin tidak lengkap sehingga tidak bisa di-decode
              requestInfo = jsonDecode(String.fromCharCodes(requestData));
            } catch (e) {
              response.statusCode = 503;
              await response.flush();
              await response.close();
              return;
            }

            //request handler
            switch (requestInfo['requestType']) {
              case 'user_authentication':
                await userAuthentication(
                  response: response,
                  data: {
                    'name': requestInfo['data']['name'],
                    'password': requestInfo['data']['password'],
                  },
                );
                break;

              case 'request_folder_info':
                await getDirectoryData(
                  response: response,
                  path: requestInfo['data']['path'],
                );
                break;

              case 'upload_file':
                await createFile(
                  response: response,
                  path: requestInfo['data']['path'],
                  data: requestInfo['data']['fileData'],
                );
                break;

              case 'download_file':
                await getFileData(
                  response: response,
                  path: requestInfo['data']['path'],
                );
                break;

              case 'create_folder':
                await createDirectory(
                  response: response,
                  path: requestInfo['data']['path'],
                );
                break;

              case 'rename':
                await renameEntity(
                  response: response,
                  entityType: requestInfo['data']['entityType'],
                  oldPath: requestInfo['data']['oldPath'],
                  newPath: requestInfo['data']['newPath'],
                );
                break;

              case 'remove':
                await removeEntity(
                  response: response,
                  entityType: requestInfo['data']['entityType'],
                  oldPath: requestInfo['data']['oldPath'],
                  newPath: requestInfo['data']['newPath'],
                );
                break;

              case 'delete':
                await deleteEntity(
                  response: response,
                  entityType: requestInfo['data']['entityType'],
                  path: requestInfo['data']['path'],
                );
                break;
            }
          } else {
            response
                .write('request you have send is not supported by this API');
          }
          // wait for writing data on client to complete
          await response.flush();
          // close the response -> end the request in client
          await response.close();
        },
      );

    },
    onDone: () => print(
        'API services has been closed and no longer listen to upcoming request'),
  );
  await stopServer(server);
}

/// Meminta input berupa alamat host dan port yang akan digunakan untuk menjalankan API ini
/// host dan port harus belum digunakan oleh Services lain
/// bila terjadi kesalahan saat pembuatan server (seringkali karena alamat host atau port yg salah) me-rethrow error
/// mereturn server bila sukses membuat server
Future<HttpServer> createServer() async {
  stdout.write(
    "\nInsert API address"
    "\nhost: ",
  );
  var address = stdin.readLineSync();
  stdout.write('port: ');
  var port = stdin.readLineSync();

  HttpServer server;
  try {
    server = await HttpServer.bind(address, int.parse(port));
  } catch (error) {
    stdout.write(
        'Error when creating server :\n$error\nTry different address or port');
    rethrow;
  }
  print('Serving on ${server.address} port: ${server.port}');
  return server;
}

void waitForStopEvent(SendPort sendPort) {
  while (true) {
    stdout.write('\nPress q to stop > ');
    var input = stdin.readLineSync();
    if (input == 'q' || input == 'Q') {
      sendPort.send(true);
      break;
    }
  }
}

/// close server(terminate services) when isolate for listen to input from user send true
Future<void> stopServer(HttpServer server) async {
  ///port untuk menerima stop event saat pengguna menghentikan api service ini
  final receivePort = ReceivePort();

  ///port untuk menerima error pada stopperIsolate
  final isolateErrorHandlerPort = ReceivePort();

  receivePort.listen(
    (isClosed) async {
      await server.close();
      isolateErrorHandlerPort.close();
      receivePort.close();
    },
  );

  isolateErrorHandlerPort.listen((error) async {
    print('Error in stopperIsolate: $error');
    receivePort.close();
    await server.close();
    isolateErrorHandlerPort.close();
  });

  //isolate for waiting input from user to stop API services
  Isolate stopperIsolate;
  try {
    stopperIsolate = await Isolate.spawn<SendPort>(
      waitForStopEvent,
      receivePort.sendPort,
      onError: isolateErrorHandlerPort.sendPort,
    );
  } catch (error) {
    print('Cannot create stopperIsolate: $error');
    receivePort.close();
    await server.close();
    return;
  }
  stopperIsolate.kill();
}

/// untuk mendapatkan info mengenai isi dari folder di [path]
Future<void> getDirectoryData({
  HttpResponse response,
  String path,
}) async {
  Map<String, List<String>> result = {
    'folder': [],
    'file': [],
  };
  try {
    if (!Directory(path).existsSync()) {
      throw 'Path $path tidak ditemukan';
    }
    Directory(path).listSync().forEach((entity) {
      switch (entity.runtimeType.toString()) {
        case '_File':
          result['file'].add(entity.path);
          break;
        case '_Directory':
          result['folder'].add(entity.path);
          break;
      }
    });
  } catch (error) {
    response.statusCode = 500;
    response.write('Error in getDirectoryData: $error');
    return;
  }
  response.write(jsonEncode(result));
}

/// untuk mendapatkan isi dari file di[path] dan megirimnya ke client
Future<void> getFileData({HttpResponse response, String path}) async {
  String file;
  try {
    if (!File(path).existsSync()) {
      throw 'Path $path tidak ditemukan';
    }
    file = File(path).readAsStringSync();
  } catch (error) {
    response.statusCode = 500;
    response.write('Error in getFileData: $error');
    return;
  }
  response.write(file);
}

Future<void> downloadFile({HttpResponse response, String path}) async {
  Uint8List file;
  try {
    if (!File(path).existsSync()) {
      throw 'Path $path tidak ditemukan';
    }
    file = File(path).readAsBytesSync();
  } catch (error) {
    response.statusCode = 500;
    response.write('Error in getFileData: $error');
    return;
  }
  response.headers.add(
      'Content-Disposition', 'attachment; filename=\"${path.split('\\').last}\"');
  response.add(file);
}

Future<void> viewFile({HttpResponse response, String path}) async {
  Uint8List file;
  try {
    if (!File(path).existsSync()) {
      throw 'Path $path tidak ditemukan';
    }
    file = File(path).readAsBytesSync();
  } catch (error) {
    response.statusCode = 500;
    response.write('Error in getFileData: $error');
    return;
  }
  response.headers.add('Content-Type', '${lookupMimeType(path)}');
  response.add(file);
}

/// membuat directory/folder pada [path], nama tidak boleh sama dengan nama entity lain di dalam directory yang sama
Future<void> createDirectory({HttpResponse response, String path}) async {
  try {
    if (Directory(path).existsSync()) {
      throw 'Folder $path sudah ada, silakan gunakan nama lain atau ubah nama folder yang sama';
    }
    Directory(path).createSync();
  } catch (error) {
    response.statusCode = 500;
    response.write('Error in createDirectory: $error');
  }
}

/// untuk membuat file pada [path] dan menulis [data] ke dalam file tersebut
/// nama tidak boleh sama dengan nama entity lain di dalam directory yang sama
Future<void> createFile({
  HttpResponse response,
  String path,
  String data,
}) async {
  final String pathWithoutExtension = path.split('.').first;
  try {
    if (File(pathWithoutExtension).existsSync()) {
      throw 'File $path sudah ada, silakan ubah nama file yang sama';
    }
    await File(pathWithoutExtension).create()
      ..writeAsStringSync(data);
  } catch (error) {
    response.statusCode = 500;
    response.write('Error in createFile: $error');
  }
}

Future<void> createFileByte({
  HttpResponse response,
  String path,
  List<int> data,
}) async {
  try {
    if (File(path).existsSync()) {
      throw 'File $path sudah ada, silakan ubah nama file yang sama';
    }
    await File(path).create()
      ..writeAsBytesSync(data);
  } catch (error) {
    response.statusCode = 500;
    response.write('Error in createFile: $error');
  }
}

/// untuk mengubah nama entitiy
/// [entityType] = tipe dari entitiy, 'File' atau 'Folder'
/// [oldPath] = lokasi entity yg ingin diubah namanya
/// [newPath] = sama dengan [oldPath] hanya saja nama entity-nya merupakan nama yang baru
/// nama tidak boleh sama dengan nama entity lain di dalam directory yang sama
Future<void> renameEntity({
  HttpResponse response,
  String entityType,
  String oldPath,
  String newPath,
}) async {
  try {
    switch (entityType) {
      case 'file':
        if (!File(oldPath).existsSync()) {
          throw 'File $oldPath yang akan diubah namanya tidak ditemukan';
        }
        if (File(newPath).existsSync()) {
          throw 'File $newPath sudah ada, silakan coba nama lain atau merubah nama file yang sama';
        }
        await File(oldPath).rename(newPath);
        break;
      case 'folder':
        if (!Directory(oldPath).existsSync()) {
          throw 'Folder $oldPath yang akan diubah namanya tidak ditemukan';
        }
        if (Directory(newPath).existsSync()) {
          throw 'Folder $newPath sudah ada, silakan coba nama lain atau merubah nama folder yang sama';
        }
        await Directory(oldPath).rename(newPath);
    }
  } catch (error) {
    response.statusCode = 500;
    response.write('Error in renameEntity: $error');
  }
}

/// untuk memindahkan entity
/// nama tidak boleh sama dengan nama entity lain di dalam directory yang sama
Future<void> removeEntity(
    {HttpResponse response,
    String entityType,
    String oldPath,
    String newPath}) async {
  try {
    switch (entityType) {
      case 'file':
        if (!File(oldPath).existsSync()) {
          throw 'File $oldPath yang akan dipindahkan tidak ditemukan';
        }
        if (File(newPath).existsSync()) {
          throw 'File $newPath sudah ada, silakan merubah nama file yang sama';
        }
        await File(oldPath).rename(newPath);
        break;
      case 'folder':
        if (!Directory(oldPath).existsSync()) {
          throw 'Folder $oldPath yang akan dipindahkan tidak ditemukan';
        }
        if (Directory(newPath).existsSync()) {
          throw 'Folder $newPath sudah ada, silakan merubah nama folder yang sama';
        }
        await Directory(oldPath).rename(newPath);
    }
  } catch (error) {
    response.statusCode = 500;
    response.write('Error in removeEntity: $error');
  }
}

/// untuk menghapus entity
Future<void> deleteEntity(
    {HttpResponse response, String entityType, String path}) async {
  try {
    switch (entityType) {
      case 'file':
        if (!File(path).existsSync()) {
          throw 'File $path yang akan dihapus tidak ditemukan, file mungkin sudah dihapus sebelumnya';
        }
        await File(path).delete();
        break;
      case 'folder':
        if (!Directory(path).existsSync()) {
          throw 'Folder $path yang akan dihapus tidak ditemukan, folder mungkin sudah dihapus sebelumnya';
        }
        await Directory(path).delete(recursive: true);
    }
  } catch (error) {
    response.statusCode = 500;
    response.write('Error in deleteEntity: $error');
  }
}
