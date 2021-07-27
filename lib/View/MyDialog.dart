import 'package:file_manager_app/Controller/MyGlobal.dart' as Global;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class InputNameDialog extends StatelessWidget {
  final String labelText;
  InputNameDialog(this.labelText);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        height: 50,
        width: 500,
        margin: EdgeInsets.all(20.0),
        child: TextField(
          autofocus: true,
          decoration: InputDecoration(
            labelText: labelText,
            border: OutlineInputBorder(),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(r'[a-zA-Z0-9_]'),
              replacementString: ' ',
            )
          ],
          onSubmitted: (value) {
            Navigator.of(context).pop(value);
          },
        ),
      ),
    );
  }
}

class ErrorDialog extends StatelessWidget {
  final String errorMessage;
  const ErrorDialog(this.errorMessage);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Text(errorMessage),
    );
  }
}

class ProgressDialog extends StatelessWidget {
  final String taskName;
  const ProgressDialog({@required this.taskName});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        height: 100,
        width: 100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(taskName),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 40,
                  width: 40,
                  child: CircularProgressIndicator(
                    backgroundColor: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showProgressDialog({@required String taskName}) async {
  final context = Global.fileManagerKey.currentContext;
  await showDialog(
    context: context,
    builder: (context) => ProgressDialog(
      taskName: taskName,
    ),
    barrierDismissible: false,
  );
}

Future<void> showErrorDialogInFileManagerPage({
  @required dynamic errorMessage,
}) async {
  final context = Global.fileManagerKey.currentContext;
  await showDialog(
    context: context,
    builder: (context) => ErrorDialog('$errorMessage'),
  );
}

Future<void> showErrorDialogInLoginPage({
  @required dynamic errorMessage,
}) async {
  final context = Global.loginPageKey.currentContext;
  await showDialog(
    context: context,
    builder: (context) => ErrorDialog('$errorMessage'),
  );
}

void closeDialogInFileManagerPage() {
  Navigator.of(
    Global.fileManagerKey.currentContext,
  ).pop();
}
