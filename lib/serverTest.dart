import 'dart:async';
import 'dart:io';
import 'dart:isolate';

void main() async {
  var server = await createServer();
  print('Serving on ${server.address} port: ${server.port}');

  server.listen((request) async {
    request.response.headers.add("Access-Control-Allow-Origin", '*');
    final uri = request.uri;
    print(
        'host: ${uri.host} \nport: ${uri.port} \nscheme: ${uri.scheme} \npath: ${uri.pathSegments} \nfragment: ${uri.fragment} \nquery: ${uri.query} \nquerylist: ${uri.queryParameters} \nquerylistall: ${uri.queryParametersAll}');
    await request.response.close();

    // List<int> dataBytes = [];
    // request.listen((data) {
    //   dataBytes.addAll(data);
    // }, onDone: () async{
    //   if(request.method == 'GET'){
    //     request.response.headers.add('Content-Type', 'application/pdf');
    //     request.response.headers.add('Content-Disposition', 'attachment; filename=mouDownloaded.pdf');
    //     request.response.add(File('mou.pdf').readAsBytesSync());
    //     await request.response.flush();
    //     await request.response.close();
    //   }
    // });
  });

  var receivePort = ReceivePort();
  receivePort.listen(
    (isStop) async {
      if (isStop) {
        await server.close();
        receivePort.close();
      }
    },
  );
  var stopperIsolate =
      await Isolate.spawn<SendPort>(stopper, receivePort.sendPort);
  stopperIsolate.kill();
}

Future<HttpServer> createServer() async {
  stdout.write(
    "\nMasukan alamat API"
    "\nhost: ",
  );
  var address = stdin.readLineSync();
  stdout.write('port: ');
  var port = stdin.readLineSync();

  HttpServer server;
  try {
    // var internetAddress = InternetAddress.lookup('$address:$port', type: InternetAddressType.any);
    server = await HttpServer.bind(address, int.parse(port));
  } catch (error) {
    stdout.write(
        'Error when creating server :\n$error\nTry different address or port');
    rethrow;
  }
  return server;
}

void stopper(SendPort sendPort) {
  while (true) {
    stdout.write('\nTekan q untuk menghentikan API ini : ');
    var input = stdin.readLineSync();
    if (input == 'q') {
      sendPort.send(true);
      break;
    }
  }
}
