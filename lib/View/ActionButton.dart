import 'dart:html';
import 'package:file_manager_app/Model/ClientRequest.dart';
import 'package:flutter/material.dart';
import 'MyDialog.dart';
import 'package:file_manager_app/Controller/FileManagerBloc.dart';
import 'package:file_manager_app/Controller/RemoveBloc.dart';

class AddEntityActionButton extends StatefulWidget {
  @override
  _AddEntityActionButtonState createState() => _AddEntityActionButtonState();
}

class _AddEntityActionButtonState extends State<AddEntityActionButton> {
  bool showOptionMenuButton = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        showOptionMenuButton ? MenuButton() : Text(''),
        SizedBox(
          height: 3,
        ),
        FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () {
            setState(() {
              showOptionMenuButton = !showOptionMenuButton;
            });
          },
        ),
      ],
    );
  }
}

class MenuButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 115,
      child: Column(
        children: [
          FloatingActionButton(
            child: Icon(
              Icons.create_new_folder,
              color: Colors.black,
            ),
            tooltip: 'Buat Folder Baru',
            backgroundColor: Colors.white,
            splashColor: Colors.red,
            onPressed: () async {
              String folderName = await showDialog(
                  context: context,
                  builder: (context) => InputNameDialog('Nama Folder'),);
              if (folderName != null && folderName != '') {
                var path = fileManagerBloc.state.path;
                showProgressDialog(
                  taskName: 'Creating New Folder',
                ).then((value) => null);
                try {
                  await CreateFolderRequest(path.path, folderName).post();
                } catch (e) {
                  await showErrorDialogInFileManagerPage(errorMessage: e);
                }
                closeDialogInFileManagerPage();
                fileManagerBloc.add(RequestNewFileManagerEvent(path));
              }
            },
          ),
          FloatingActionButton(
            child: Icon(
              Icons.upload_file,
              color: Colors.black,
            ),
            tooltip: 'Upload File',
            backgroundColor: Colors.white,
            splashColor: Colors.red,
            onPressed: () async {
              var inputFile = FileUploadInputElement()..multiple = true;
              inputFile.click();

              inputFile.onChange.listen((event) async {
                showProgressDialog(taskName: 'Uploading File')
                    .then((value) => null);
                var path = fileManagerBloc.state.path;
                final unuploadableFile = <String>[];
                for (var rawFile in inputFile.files) {
                  // file that has name contained more than one dot(.) is forbidden
                  if (rawFile.name.split('.').length > 2) {
                    unuploadableFile.add(rawFile.name);
                    continue;
                  }
                  final r = FileReader();
                  r.readAsArrayBuffer(rawFile);
                  await for (var event in r.onLoadEnd) {
                    try {
                      await UploadFileRequest(
                        '${path.path}\\${rawFile.name}',
                        r.result,
                      ).post();
                    } catch (e) {
                      await showErrorDialogInFileManagerPage(errorMessage: e);
                    }
                    break;
                  }
                }
                closeDialogInFileManagerPage();
                fileManagerBloc.add(RequestNewFileManagerEvent(path));
                if (unuploadableFile.isNotEmpty) {
                  await showErrorDialogInFileManagerPage(
                      errorMessage:
                          'Nama file tidak boleh mengandung titik(.)\nFile berikut gagal diupload :\n${unuploadableFile.join('\n')}');
                }
              });
            },
          ),
        ],
      ),
    );
  }
}

class RemoveOptionButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 25,
        ),
        SizedBox(
          width: 100,
          height: 40,
          child: FloatingActionButton(
            child: Text('Pindahkan'),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(30))),
            onPressed: () async {
              removeBloc.add(DoneEvent(
                newPath: fileManagerBloc.path.path,
              ));
            },
          ),
        ),
        SizedBox(
          width: 10,
        ),
        SizedBox(
          width: 60,
          height: 40,
          child: FloatingActionButton(
            child: Text('Batal'),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(35))),
            backgroundColor: Colors.red,
            onPressed: () => removeBloc.add(CancelEvent()),
          ),
        )
      ],
    );
  }
}
