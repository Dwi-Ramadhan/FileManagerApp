import 'dart:io';
import 'package:postgres/postgres.dart';

Future<void> userAuthentication(
    {HttpResponse response, Map<String, String> data}) async {
  var connection = PostgreSQLConnection(
    'localhost',
    5432,
    'file',
    username: data['name'],
    password: data['password'],
  );
  try {
    await connection.open();
  } catch (e) {
    response.statusCode = 500;
    response.write('Login gagal, periksa kembali username dan password anda');
    return;
  } finally {
    await connection.close();
  }
}
