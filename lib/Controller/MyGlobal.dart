import 'package:flutter/material.dart';

final fileManagerKey = GlobalKey<ScaffoldState>();
final loginPageKey = GlobalKey<ScaffoldState>();

Future<void> changeAppPage() async {
  await Navigator.of(loginPageKey.currentContext)
      .pushNamedAndRemoveUntil('fileManagerPage', (route) => false);
}

// id tipe pihak_terlibat tahun keberlakuan keterangan
