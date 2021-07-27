import 'package:file_manager_app/Model/ClientRequest.dart';
import 'package:file_manager_app/Controller/FileManagerBloc.dart';
import 'package:file_manager_app/Model/Entity.dart';
import 'package:file_manager_app/View/MyDialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RemoveEvent {
  const RemoveEvent();
}

class InitialEvent extends RemoveEvent {
  final List<Entity> entities;
  const InitialEvent({this.entities});
}

class DoneEvent extends RemoveEvent {
  final String newPath;
  const DoneEvent({
    this.newPath,
  });
}

class CancelEvent extends RemoveEvent {
  const CancelEvent();
}

/// Menagani RemoveEvent:
/// - InitialEvent : memicu tampilan untuk memindahkan entity dan memberi info mengenai entitity yg akan dipindahkan(path awal dan tipe entity)
/// - DoneEvent : menonaktifkan tampilan untuk memindahkan entity, dan mengirim RemoveRequest
/// - CancelEvent : menonaktifkan tampilan untuk memindahkan entity saja
/// meng-emit state berupa bool, true untuk menampilkan dan false untuk menyembunyikannya
class RemoveBloc extends Bloc<RemoveEvent, bool> {
  RemoveBloc() : super(false);

  /*late*/ List<Entity> entities;
  /*late*/ List<EntityPath> oldPathList;
  /*late*/ List<EntityType> entityTypeList;

  @override
  Stream<bool> mapEventToState(RemoveEvent event) async* {
    if (event is InitialEvent) {
      entities = event.entities;
      oldPathList = entities.map((entity) => entity.path).toList();
      entityTypeList = entities.map((entity) => entity.entityType).toList();
      yield true;
    } else if (event is DoneEvent) {
      yield false;
      showProgressDialog(taskName: 'Memindahkan').then((value) => null);
      await _removeEntity(event.newPath);
      closeDialogInFileManagerPage();
      fileManagerBloc.refreshFileManager();
    } else if (event is CancelEvent) {
      yield false;
    }
  }

  Future<void> _removeEntity(String targetPath) async {
    final successRemoved = <String>[];
    try {
      for (int i = 0; i < oldPathList.length; ++i) {
        final oldPath = oldPathList[i];
        final name = oldPath.pathSegmented.last;
        final newPath = '$targetPath\\$name';
        await RemoveRequest(entityTypeList[i], oldPath.path, newPath).post();
        successRemoved.add(name);
      }
    } catch (e) {
      await showErrorDialogInFileManagerPage(
        errorMessage:
            '$e ${successRemoved.isEmpty ? '' : '\nEntity berikut berhasil dipindahkan: \n${successRemoved.join('\n')}'}',
      );
    }
  }
}

final removeBloc = RemoveBloc();
