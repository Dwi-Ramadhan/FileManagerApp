import 'package:file_manager_app/Model/Entity.dart';
import 'package:flutter/material.dart';
import 'EntityWidget.dart';
import 'package:file_manager_app/Controller/FileManagerBloc.dart';

class FileManager extends StatelessWidget {
  final EntityPath path;
  final List<Entity> entities;
  FileManager(this.path, this.entities);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.only(top: 5),
      itemCount: entities.length,
      itemBuilder: (context, index) {
        final entity = entities[index];
        return EntityWidget(
          entity,
          key: UniqueKey(),
        );
      },
    );
  }
}

class LocationNavigatorWidget extends PreferredSize {
  final List<String> path;
  LocationNavigatorWidget(this.path);

  @override
  Size get preferredSize => Size.fromHeight(10);

  @override
  Widget build(BuildContext context) {
    var children = <LocationPointer>[];
    for (int i = 0; i < path.length; ++i) {
      children.add(
        LocationPointer(EntityPath.fromListOfString(path.sublist(0, i + 1))),
      );
    }

    return Container(
      width: double.infinity,
      color: Colors.black,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: children,
        ),
      ),
    );
  }
}

class LocationPointer extends StatelessWidget {
  final EntityPath path;
  LocationPointer(this.path);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Row(
        children: [
          SizedBox(
            width: 5,
          ),
          Text(
            //name of directory currently in
            path.pathSegmented.last, style: TextStyle(color: Colors.white),
          ),
          Icon(
            Icons.arrow_right,
            color: Colors.white,
          )
        ],
      ),
      onTap: () {
        fileManagerBloc.add(RequestNewFileManagerEvent(path));
      },
    );
  }
}
