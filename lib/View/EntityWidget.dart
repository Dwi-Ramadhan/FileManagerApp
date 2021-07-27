import 'package:file_manager_app/Controller/RemoveBloc.dart' as RemoveBloc;
import 'package:file_manager_app/Controller/SelectEntityBloc.dart';
import 'package:file_manager_app/Model/ClientRequest.dart';
import 'package:file_manager_app/Model/Entity.dart';
import 'package:file_manager_app/View/MyDialog.dart';
import 'package:flutter/rendering.dart';
import 'package:file_manager_app/Controller/FileManagerBloc.dart';
import 'package:flutter/material.dart';

class EntityWidget extends StatelessWidget {
  /// model this widget represent of
  final Entity entity;
  const EntityWidget(this.entity, {key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Material(
        elevation: 20.0,
        shadowColor: Colors.blue,
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: (entity.entityType is FileType)
                          ? Icon(
                              Icons.insert_drive_file,
                              color: Colors.blue,
                            )
                          : Icon(
                              Icons.folder,
                              color: Colors.orange,
                            ),
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    Flexible(
                      child: Text(
                        entity.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  ],
                ),
                onTap: selectEntityBloc.state
                    ? null
                    : () {
                        if (entity.entityType is FolderType) {
                          fileManagerBloc
                              .add(RequestNewFileManagerEvent(entity.path));
                        } else if (entity.entityType is FileType) {
                          ViewFileRequest(entity.path.path).post();
                        }
                      },
              ),
            ),
            selectEntityBloc.state
                ? SelectEntityBox(
                    entity: entity,
                  )
                : EntityActionMenu(entity),
          ],
        ),
      ),
      margin: EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 0.0),
    );
  }
}

class EntityActionMenu extends StatefulWidget {
  final Entity entity;
  EntityActionMenu(this.entity);

  @override
  _EntityActionMenuState createState() => _EntityActionMenuState();
}

class _EntityActionMenuState extends State<EntityActionMenu> {
  /// to get position of actionMenu to showOptionMenu accordingly
  final _actionMenuKey = GlobalKey();

  /// decide whether user hover or not, show ActionMenu if true, hide it if false
  bool mouseHover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      child: Container(
        key: _actionMenuKey,
        width: 100,
        height: 50,
        color: Colors.grey.shade300,
        child: mouseHover
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    child: Icon(
                      Icons.cloud_download_rounded,
                      color: Colors.blue,
                    ),
                    onTap: () async => await downloadEntity([widget.entity]),
                  ),
                  GestureDetector(
                    child: Icon(
                      Icons.create,
                      color: Colors.red,
                    ),
                    onTap: () => _showEditMenu(context, _actionMenuKey),
                  ),
                ],
              )
            : null,
      ),
      onHover: (event) {
        setState(() {
          mouseHover = true;
        });
      },
      onExit: (event) {
        setState(() {
          mouseHover = false;
        });
      },
    );
  }

  void _showEditMenu(BuildContext context, GlobalKey key) async {
    var _renderBox = key.currentContext.findRenderObject() as RenderBox;
    var _renderBoxSize = _renderBox.size;
    var _position = RelativeRect.fromRect(
      Rect.fromPoints(
        _renderBox.localToGlobal(Offset.zero),
        _renderBox.localToGlobal(
          Offset(
            _renderBoxSize.width,
            _renderBoxSize.height,
          ),
        ),
      ),
      Rect.fromPoints(Offset(0, 0), Offset(0, 0)),
    );

    var _selectedOption = await showMenu(
      context: context,
      position: _position,
      items: [
        PopupMenuItem(
          child: Text('Ubah Nama'),
          value: 1,
        ),
        PopupMenuItem(
          child: Text('Pindahkan'),
          value: 2,
        ),
        PopupMenuItem(
          child: Text('Hapus'),
          value: 3,
        ),
      ],
    );

    switch (_selectedOption) {
      //option 'Ubah Nama' selected
      case 1:
        var _newName = await showDialog(
          context: context,
          builder: (context) => InputNameDialog('Nama Baru'),
        );
        if (_newName != null && _newName != '') {
          await widget.entity.renameEntity(_newName);
        }
        break;
      //option 'Pindahkan' selected
      case 2:
        RemoveBloc.removeBloc.add(
          RemoveBloc.InitialEvent(entities: [widget.entity]),
        );
        break;
      //option 'Hapus 'selected
      case 3:
        await deleteEntity([widget.entity]);
    }
  }
}

class SelectEntityBox extends StatefulWidget {
  final Entity entity;
  SelectEntityBox({this.entity});

  @override
  _SelectEntityBoxState createState() => _SelectEntityBoxState();
}

class _SelectEntityBoxState extends State<SelectEntityBox> {
  @override
  Widget build(BuildContext context) {
    return Checkbox(
        value: widget.entity.isSelected,
        onChanged: (isSelected) {
          if (isSelected) {
            //selected
            selectEntityBloc.add(OnSelectEvent(widget.entity));
          } else {
            //not selected
            selectEntityBloc.add(OnUnselectEvent(widget.entity));
          }
          setState(() => widget.entity.isSelected = isSelected);
        });
  }
}
