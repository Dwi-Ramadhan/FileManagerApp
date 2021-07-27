import 'package:file_manager_app/Controller/FileManagerBloc.dart';
import 'package:file_manager_app/Controller/MyGlobal.dart' as Global;
import 'package:file_manager_app/Controller/RemoveBloc.dart'
    show removeBloc, RemoveBloc;
import 'package:file_manager_app/Controller/SelectEntityBloc.dart';
import 'package:file_manager_app/Model/Entity.dart';
import 'package:flutter/material.dart';
import 'FileManager.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'ActionButton.dart';

class FileManagerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => fileManagerBloc
              ..add(RequestNewFileManagerEvent(EntityPath('root'))),
          ),
          BlocProvider(create: (context) => removeBloc),
          BlocProvider(create: (context) => selectEntityBloc),
        ],
        child: BlocBuilder<RemoveBloc, bool>(
          builder: (context, isShowRemoveButton) {
            return BlocBuilder<SelectEntityBloc, bool>(
              builder: (context, isSelectionModeOn) {
                return BlocBuilder<FileManagerBloc, FileManagerState>(
                  builder: (context, state) {
                    return Scaffold(
                      key: Global.fileManagerKey,
                      appBar: PreferredSize(
                        preferredSize:
                            Size.fromHeight(isSelectionModeOn ? 56 : 80),
                        child: AppBar(
                          title: Text(
                            'File Manager App',
                          ),
                          centerTitle: !isSelectionModeOn,
                          actions: isSelectionModeOn
                              ? [
                                  IconButton(
                                    icon: Icon(
                                      Icons.cloud_download,
                                    ),
                                    onPressed: () {
                                      selectEntityBloc.add(DoneEvent(
                                        requestType: optionForEntities.download,
                                      ));
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.drive_file_move,
                                      color: Colors.orange,
                                    ),
                                    onPressed: () {
                                      selectEntityBloc.add(DoneEvent(
                                        requestType: optionForEntities.remove,
                                      ));
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      selectEntityBloc.add(DoneEvent(
                                        requestType: optionForEntities.delete,
                                      ));
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.select_all_outlined),
                                    onPressed: () {
                                      selectEntityBloc.add(SelectAllEvent());
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.cancel_sharp,
                                      size: 30,
                                    ),
                                    onPressed: () {
                                      selectEntityBloc.add(CancelEvent());
                                    },
                                  ),
                                ]
                              : [
                                  IconButton(
                                    icon: Icon(Icons.select_all),
                                    onPressed: () {
                                      selectEntityBloc.add(InitialEvent());
                                    },
                                  )
                                ],
                          bottom: isSelectionModeOn
                              ? null
                              : LocationNavigatorWidget(
                                  state.path.pathSegmented),
                        ),
                      ),
                      body: FileManager(state.path, state.entities),
                      floatingActionButton: isSelectionModeOn
                          ? null
                          : (isShowRemoveButton
                              ? RemoveOptionButton()
                              : AddEntityActionButton()),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
