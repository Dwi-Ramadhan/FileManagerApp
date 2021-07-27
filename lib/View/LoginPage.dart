import 'package:file_manager_app/Controller/LoginBloc.dart';
import 'package:file_manager_app/Controller/MyGlobal.dart' as Global;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginPage extends StatelessWidget {
  const LoginPage();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        key: Global.loginPageKey,
        body: LayoutBuilder(
          builder: (context, constraint) {
            return Container(
              height: constraint.maxHeight,
              width: constraint.maxWidth,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey, Colors.black],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: LoginForm(),
            );
          },
        ),
      ),
    );
  }
}

class LoginForm extends StatelessWidget {
  LoginForm();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => loginBloc,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RichText(
                text: TextSpan(
              text: 'L',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'PermanentMarker',
                shadows: [
                  BoxShadow(
                      color: Colors.blue,
                      offset: Offset(1, 2),
                      spreadRadius: 3,
                      blurRadius: 5)
                ],
              ),
              children: [
                TextSpan(
                    text: 'O',
                    style: TextStyle(
                      shadows: [
                        BoxShadow(
                            color: Colors.green,
                            offset: Offset(1, 2),
                            spreadRadius: 3,
                            blurRadius: 5)
                      ],
                    )),
                TextSpan(
                    text: 'G',
                    style: TextStyle(
                      shadows: [
                        BoxShadow(
                            color: Colors.red,
                            offset: Offset(1, 2),
                            spreadRadius: 3,
                            blurRadius: 5)
                      ],
                    )),
                TextSpan(
                    text: 'I',
                    style: TextStyle(
                      shadows: [
                        BoxShadow(
                            color: Colors.yellow,
                            offset: Offset(1, 2),
                            spreadRadius: 3,
                            blurRadius: 5)
                      ],
                    )),
                TextSpan(
                    text: 'N',
                    style: TextStyle(
                      shadows: [
                        BoxShadow(
                            color: Colors.deepPurpleAccent,
                            offset: Offset(1, 2),
                            spreadRadius: 3,
                            blurRadius: 5)
                      ],
                    )),
              ],
            )),
            SizedBox(
              height: 35,
            ),
            InputLogin(
              inputLoginType: InputLoginType.inputName,
            ),
            SizedBox(
              height: 20,
            ),
            InputLogin(
              inputLoginType: InputLoginType.inputPassword,
            ),
            SizedBox(
              height: 20,
            ),
            SizedBox(
              width: 100,
              height: 30,
              child: FloatingActionButton(
                backgroundColor: Colors.black,
                splashColor: Colors.blue,
                child: Text(
                  'Masuk', /*style: TextStyle(fontFamily: 'PermanentMarker',),*/
                ),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.blue),
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                ),
                onPressed: () {
                  _formKey.currentState.save();
                  loginBloc.add(SubmitEvent());
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

typedef void InputFunc(String v);

class InputLogin extends StatelessWidget {
  final InputLoginType inputLoginType;
  const InputLogin({this.inputLoginType});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 50,
      padding: EdgeInsets.only(left: 5, right: 10),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(
            color: (inputLoginType == InputLoginType.inputName)
                ? Colors.green
                : Colors.red),
        borderRadius: BorderRadius.all(Radius.circular(25)),
      ),
      child: TextFormField(
        obscureText:
            (inputLoginType == InputLoginType.inputName) ? false : true,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: (inputLoginType == InputLoginType.inputName)
              ? Icon(
                  Icons.person,
                  color: Colors.blue,
                )
              : Icon(
                  Icons.lock,
                  color: Colors.orange,
                ),
          border: InputBorder.none,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9_]'))
        ],
        onSaved: (values) {
          loginBloc.add(InputEvent(type: inputLoginType, data: values));
        },
      ),
    );
  }
}
