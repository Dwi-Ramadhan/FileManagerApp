import 'package:file_manager_app/Controller/FileManagerBloc.dart';
import 'package:file_manager_app/Controller/RemoveBloc.dart' as RemoveBloc;
import 'package:file_manager_app/Model/Entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SelectEntityEvent {
  const SelectEntityEvent();
}

class InitialEvent extends SelectEntityEvent {
  const InitialEvent();
}

class OnSelectEvent extends SelectEntityEvent {
  final Entity entity;
  const OnSelectEvent(this.entity);
}

class OnUnselectEvent extends SelectEntityEvent {
  final Entity entity;
  const OnUnselectEvent(this.entity);
}

class DoneEvent extends SelectEntityEvent {
  final optionForEntities requestType;
  const DoneEvent({this.requestType});
}

class CancelEvent extends SelectEntityEvent {
  const CancelEvent();
}

class SelectAllEvent extends SelectEntityEvent {
  const SelectAllEvent();
}

enum optionForEntities {
  download,
  remove,
  delete,
}

/// Menangani SelectEntityEvent:
/// - InitialEvent: memicu tampilan untuk menyeleksi entity
/// - InProgressEvent: mengirim info entity yang dipilih
/// - DoneEvent: menonaktifkan tampilan untuk menyeleksi entity
/// - CancelRequest: menonaktifkan tampilan untuk menyeleksi entity saja
/// Meng-emit state berupa bool, true untuk menampilkan tampilan untuk menyeleksi entity dan false untuk menyembunyikannya
class SelectEntityBloc extends Bloc<SelectEntityEvent, bool> {
  SelectEntityBloc() : super(false);

  final _selectedEntities = <Entity>[];

  @override
  Stream<bool> mapEventToState(SelectEntityEvent event) async* {
    if (event is InitialEvent) {
      yield true;
    } else if (event is OnSelectEvent) {
      _selectedEntities.add(event.entity);
    } else if (event is SelectAllEvent) {
      // clear previous selectedEntities (that user probably select before choose select all)so that there is no duplicate entity
      _selectedEntities.clear();
      // add all entities in current directory to selectedEntities
      _selectedEntities.addAll(fileManagerBloc.state.entities);
      // update all EntityWidget in current directory to selected
      fileManagerBloc.refreshFileManagerWithAllEntitiesSelected();
    } else if (event is OnUnselectEvent) {
      _selectedEntities.remove(event.entity);
    } else if (event is DoneEvent) {
      switch (event.requestType) {
        case optionForEntities.download:
          downloadEntity(_selectedEntities.toList()).then((value) => null);
          fileManagerBloc.refreshFileManager();
          break;
        case optionForEntities.remove:
          RemoveBloc.removeBloc.add(RemoveBloc.InitialEvent(
            entities: _selectedEntities.toList(),
          ));
          break;
        case optionForEntities.delete:
          await deleteEntity(_selectedEntities.toList());
      }
      _selectedEntities.clear();
      yield false;
    } else if (event is CancelEvent) {
      _selectedEntities.clear();
      fileManagerBloc.refreshFileManager();
      yield false;
    }
  }
}

var selectEntityBloc = SelectEntityBloc();
