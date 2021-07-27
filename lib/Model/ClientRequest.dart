import 'dart:convert';
import 'dart:html';
import 'package:file_manager_app/Model/Entity.dart';
import 'package:http/http.dart' as http;
import 'package:http_retry/http_retry.dart';

/// Parent bagi seluruh class yg digunakan utk melakukan request ke server.
/// Class ini memegang data-data umum yg diperlukan utk membuat request ke server.
abstract class ClientRequest {
  /// alamat API kemana request akan dikirim
  final serverUrl = 'http://localhost:4040';

  /// data yg akan dikirim ke server, [request] akan diinisialisasi
  /// oleh setiap class yg meng-extend class ini
  Map request = {'requestType': '', 'data': {}};

  String requestToJson() => jsonEncode(request);
}

class UserAuthenticationRequest extends ClientRequest {
  final String name, password;

  UserAuthenticationRequest({this.name, this.password}) {
    request['requestType'] = 'user_authentication';
    request['data']['name'] = name;
    request['data']['password'] = password;
  }

  Future<void> post() async {
    var client = RetryClient(http.Client());

    http.Response respon;
    try {
      respon = await client.post(
        Uri.parse(serverUrl),
        body: requestToJson(),
      );
    } catch (error) {
      throw 'Error when sending UserAuthenticationRequest : $error';
    } finally {
      client.close();
    }

    if (respon.statusCode != 200) {
      throw respon.body;
    }
  }
}

/// Digunakan untuk me-request EntityInfo dari sebuah folder/Directory
/// yg disimpan di server. Info yang diminta berupa nama dari entity didalam
/// folder tersebut baik berupa file maupun folder didalamnya
class EntitiesInfoRequest extends ClientRequest {
  ///path dari directory/folder pada server yang ingin diminta infonya.
  final String path;

  EntitiesInfoRequest(this.path) {
    request['requestType'] = 'request_folder_info';
    request['data']['path'] = path;
  }

  Future<Map<String, List<String>>> post() async {
    var client = RetryClient(http.Client());

    http.Response respon;
    try {
      respon = await client.post(
        Uri.parse(serverUrl),
        body: requestToJson(),
      );
    } catch (error) {
      throw 'Error when sending Entities Info Request : $error';
    } finally {
      client.close();
    }

    if (respon.statusCode == 200) {
      var json = jsonDecode(respon.body);
      List filesInfo = json['file'];
      List foldersInfo = json['folder'];

      Map<String, List<String>> entitiesInfo = {
        'file': filesInfo.cast<String>(),
        'folder': foldersInfo.cast<String>(),
      };
      return entitiesInfo;
    } else {
      throw respon.body;
    }
  }
}

/// Digunakan untuk mengupload [fileInfo] ke server.
class UploadFileRequest extends ClientRequest {
  /// Berisi path dan isi data dari file tersebut. Gunakan FileInfo class utk
  /// meng-convert data-data itu ke String
  String path;
  List<int> fileData;

  UploadFileRequest(this.path, this.fileData);

  Future<void> post() async {
    var client = RetryClient(http.Client(), retries: 7);

    http.Response respon;
    try {
      respon = await client.post(
        Uri.parse('http://localhost:4040?requestType=upload&path=$path'),
        body: fileData,
        headers: {
          'Keep-Alive': 'timeout=360',
        },
      );
    } catch (error) {
      throw 'Error when sending Upload File Request : $error';
    } finally {
      client.close();
    }
    if (respon.statusCode != 200) {
      throw respon.body;
    }
  }
}

class ViewFileRequest extends ClientRequest{
  final String path;
  ViewFileRequest(this.path);

  void post(){
    AnchorElement(
        href:
        '$serverUrl?requestType=viewFile&path=$path')
      ..setAttribute('target', '_blank')
      ..click();
  }
}

class DownloadFileRequest extends ClientRequest{
  final List<Entity> entities;
  DownloadFileRequest(this.entities);

  Future<void> post() async {
    for (var entity in entities) {
      try {
        if (entity.entityType is FileType) {
          AnchorElement(
              href:
              '$serverUrl?requestType=download&path=${entity.path.path}')
              .click();
          await Future.delayed(Duration(seconds: 1));
        } else {
          //entityType is FolderType
          var entitiesInfo = await EntitiesInfoRequest(entity.path.path).post();
          var files = entitiesInfo['file'];

          //download each file in this folder
          for (String filePath in files) {
            AnchorElement(
                href:
                '$serverUrl?requestType=download&path=$filePath')
                .click();
            await Future.delayed(Duration(seconds: 1));
          }
        }
      } catch (e) {
        throw e;
      }
    }
  }
}

/// Meminta API pada server untuk membuat Directory/folder pada [path] dan dgn
/// nama [folderName]
class CreateFolderRequest extends ClientRequest {
  String path, folderName;

  CreateFolderRequest(this.path, this.folderName) {
    request['requestType'] = 'create_folder';
    request['data']['path'] = '$path\\$folderName';
  }

  Future<void> post() async {
    var client = RetryClient(http.Client());
    http.Response respon;
    try {
      respon = await client.post(
        Uri.parse(serverUrl),
        body: requestToJson(),
      );
    } catch (error) {
      throw 'Error when sending Create Folder Request : $error';
    } finally {
      client.close();
    }
    if (respon.statusCode != 200) {
      throw respon.body;
    }
  }
}

/// Mengubah nama entity pada [path] dengan [newName].
class RenameRequest extends ClientRequest {
  EntityType entityType;
  EntityPath path;
  String newName;

  RenameRequest(this.entityType, this.path, this.newName) {
    request['requestType'] = 'rename';
    if(entityType is FileType){
      // add fileExtension to newName if there is one
      final oldName = path.pathSegmented.last;
      if(oldName.contains('.')){
        newName += '.${oldName.split('.').last}';
      }
    }
    final String pathWithoutName = EntityPath.fromListOfString(
            path.pathSegmented.sublist(0, path.pathSegmented.length - 1))
        .path;
    request['data']['entityType'] = entityType.toString();
    request['data']['oldPath'] = path.path;
    request['data']['newPath'] = '$pathWithoutName\\$newName';
  }

  Future<void> post() async {
    var client = RetryClient(http.Client());
    http.Response respon;
    try {
      respon = await client.post(Uri.parse(serverUrl), body: requestToJson());
    } catch (error) {
      throw 'Error when sending Rename Request : $error';
    } finally {
      client.close();
    }
    if (respon.statusCode != 200) {
      throw respon.body;
    }
  }
}

/// Memindahkan entity pada [oldPath] ke [newPath]
class RemoveRequest extends ClientRequest {
  EntityType entityType;
  String oldPath, newPath;

  RemoveRequest(this.entityType, this.oldPath, this.newPath) {
    request['requestType'] = 'remove';
    request['data']['entityType'] = entityType.toString();
    request['data']['oldPath'] = oldPath;
    request['data']['newPath'] = newPath;
  }

  Future<void> post() async {
    var client = RetryClient(http.Client());
    http.Response respon;
    try {
      respon = await client.post(Uri.parse(serverUrl), body: requestToJson());
    } catch (error) {
      throw 'Error when sending Remove Request : $error';
    } finally {
      client.close();
    }
    if (respon.statusCode != 200) {
      throw respon.body;
    }
  }
}

/// Meminta API pd server untuk menghapus entity di [path]
class DeleteRequest extends ClientRequest {
  EntityType entityType;
  String path;

  DeleteRequest(this.entityType, this.path) {
    request['requestType'] = 'delete';
    request['data']['entityType'] = entityType.toString();
    request['data']['path'] = path;
  }

  Future<void> post() async {
    var client = RetryClient(http.Client());
    http.Response respon;
    try {
      respon = await client.post(Uri.parse(serverUrl), body: requestToJson());
    } catch (error) {
      throw 'Error when sending Delete Request : $error';
    } finally {
      client.close();
    }
    if (respon.statusCode != 200) {
      throw respon.body;
    }
  }
}
