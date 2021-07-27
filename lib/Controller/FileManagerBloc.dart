import 'package:file_manager_app/Model/ClientRequest.dart';
import 'package:file_manager_app/Model/Entity.dart';
import 'package:file_manager_app/View/MyDialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RequestNewFileManagerEvent {
  final EntityPath path;
  final bool isAllEntitiesSelected;
  const RequestNewFileManagerEvent(this.path,
      {this.isAllEntitiesSelected = false});
}

class FileManagerState {
  final EntityPath path;
  List<Entity> entities;
  FileManagerState(this.path, this.entities);
}

class FileManagerBloc
    extends Bloc<RequestNewFileManagerEvent, FileManagerState> {
  var path = EntityPath('');

  FileManagerBloc()
      : super(
          FileManagerState(
            EntityPath(''),
            [],
          ),
        );

  @override
  Stream<FileManagerState> mapEventToState(
      RequestNewFileManagerEvent event) async* {
    try {
      path = event.path;
      Map<String, List<String>> entitiesInfo =
          await EntitiesInfoRequest(path.path).post();

      // convert entityInfo to Entity object
      final entities = <Entity>[];
      for (final folderPath in entitiesInfo['folder']) {
        entities.add(
          Entity(
            FolderType(),
            EntityPath(folderPath),
            isSelected: event.isAllEntitiesSelected,
          ),
        );
      }
      for (final filePath in entitiesInfo['file']) {
        entities.add(
          Entity(
            FileType(),
            EntityPath(filePath),
            isSelected: event.isAllEntitiesSelected,
          ),
        );
      }

      yield FileManagerState(path, entities);
    } catch (e) {
      await showErrorDialogInFileManagerPage(errorMessage: e);
    }
  }

  void refreshFileManager() {
    add(RequestNewFileManagerEvent(this.path));
  }

  void refreshFileManagerWithAllEntitiesSelected() {
    add(RequestNewFileManagerEvent(
      this.path,
      isAllEntitiesSelected: true,
    ));
  }
}

var fileManagerBloc = FileManagerBloc();
