import 'package:flutter/material.dart';
import 'View/FileManagerPage.dart';
import 'View/LoginPage.dart';

void main() => runApp(FileManagerApp());

class FileManagerApp extends MaterialApp {
  FileManagerApp()
      : super(
          title: 'File Manager App',
          debugShowCheckedModeBanner: false,
          initialRoute: 'loginPage',
          routes: {
            'loginPage': (BuildContext ctx) => LoginPage(),
            'fileManagerPage': (BuildContext ctx) => FileManagerPage(),
          },
        );
}
