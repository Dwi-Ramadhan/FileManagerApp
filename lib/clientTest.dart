// import 'package:mysql1/mysql1.dart';
//
// void main()async{
//   var settings = ConnectionSettings(
//       host: 'localhost',
//       port: 3306,
//       user: 'root',
//       password: 'root',
//       db: 'test'
//   );
//   var conn = await MySqlConnection.connect(settings);
//   var result = await conn.query('SELECT * FROM user;');
//   print('${result.fields}');
//   await conn.close();
// }

// import 'package:postgres/postgres.dart';
//
// void main()async{
//   var connection = PostgreSQLConnection("localhost", 5432, "file", username: "root", password: "root");
//   await connection.open();
//
//   List<List<dynamic>> results = await connection.query("SELECT nama FROM atribut;");
//   for (final row in results) {
//     print('$row');
//   }
//   await connection.close();
// }
import 'package:http/http.dart' as http;

class cobah {
  final String a, b;
  const cobah(this.a, this.b);

  @override
  bool operator ==(Object other) {
    return other is cobah && this.a == other.a && this.b == other.b;
  }

  @override
  int get hashCode => a.hashCode ^ b.hashCode;

  @override
  String toString() => '$a,$b';
}

void main() async {
  var resp  = await http.post(Uri.parse('https://youtu.be/x2-rSnhpw0g'));
  print('${resp.body}');
}
