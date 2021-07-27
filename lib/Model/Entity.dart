import 'package:file_manager_app/Model/ClientRequest.dart';
import 'package:file_manager_app/Controller/FileManagerBloc.dart';
import 'package:file_manager_app/View/MyDialog.dart';

class Entity {
  Entity(this.entityType, this.path, {this.isSelected = false}) {
    name = path.pathSegmented.last;
  }

  ///just FileType or FolderType only
  final EntityType entityType;
  /*late*/ String name;
  final EntityPath path;
  bool isSelected;

  @override
  bool operator ==(Object other) =>
      other is Entity && other.entityType == entityType && other.path == path;

  @override
  int get hashCode => super.hashCode ^ entityType.hashCode ^ path.hashCode;

  Future<void> renameEntity(String newName) async {
    showProgressDialog(
      taskName: 'Renaming',
    ).then((value) => null);
    try {
      await RenameRequest(entityType, path, newName).post();
    } catch (e) {
      await showErrorDialogInFileManagerPage(errorMessage: e);
    }
    closeDialogInFileManagerPage();
    fileManagerBloc.refreshFileManager();
  }
}

class EntityPath {
  String path;
  List<String> pathSegmented;

  EntityPath(this.path) {
    pathSegmented = path.split(r'\');
  }

  EntityPath.fromListOfString(List<String> pathSegmented) {
    String path = '';
    for (int i = 0; i < pathSegmented.length; ++i) {
      path += pathSegmented[i];
      if (i != pathSegmented.length - 1) {
        path += r'\';
      }
    }
    this.path = path;
    this.pathSegmented = pathSegmented;
  }
}

abstract class EntityType {
  const EntityType();
}

class FolderType extends EntityType {
  const FolderType();
  @override
  String toString() => 'folder';
}

class FileType extends EntityType {
  const FileType();
  @override
  String toString() => 'file';
}

Future<void> downloadEntity(List<Entity> entities) async {
  showProgressDialog(taskName: 'Mengunduh').then((value) => null);
  try{
    await DownloadFileRequest(entities).post();
  }catch(e){
    await showErrorDialogInFileManagerPage(errorMessage: e);
  }
  closeDialogInFileManagerPage();
}

Future<void> deleteEntity(List<Entity> entities) async {
  showProgressDialog(taskName: 'Menghapus').then((value) => null);
  final successDeleted = <String>[];
  try {
    for (final entity in entities) {
      await DeleteRequest(entity.entityType, entity.path.path).post();
      successDeleted.add(entity.path.pathSegmented.last);
    }
  } catch (e) {
    await showErrorDialogInFileManagerPage(
      errorMessage:
          '$e ${successDeleted.isEmpty ? '' : '\nEntity berikut berhasil dihapus: \n${successDeleted.join('\n')}'}',
    );
  }
  closeDialogInFileManagerPage();
  fileManagerBloc.refreshFileManager();
}
