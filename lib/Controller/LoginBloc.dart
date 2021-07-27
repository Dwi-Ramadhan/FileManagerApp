import 'package:file_manager_app/Model/ClientRequest.dart';
import 'package:file_manager_app/Controller/MyGlobal.dart' as Global;
import 'package:file_manager_app/View/MyDialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginEvent {
  const LoginEvent();
}

enum InputLoginType {
  inputName,
  inputPassword,
}

class InputEvent extends LoginEvent {
  final InputLoginType type;
  final String data;
  const InputEvent({this.type, this.data});
}

class SubmitEvent extends LoginEvent {
  const SubmitEvent();
}

class LoginState {
  const LoginState();
}

class ErrorState extends LoginState {
  const ErrorState();
}

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(LoginState());

  var userData = <String, String>{
    'name': '',
    'password': '',
  };

  @override
  Stream<LoginState> mapEventToState(LoginEvent event) async* {
    if (event is InputEvent) {
      switch (event.type) {
        case InputLoginType.inputName:
          userData['name'] = event.data;
          break;
        case InputLoginType.inputPassword:
          userData['password'] = event.data;
      }
    } else if (event is SubmitEvent) {
      if (userData['name'] == '' || userData['password'] == '') {
        await showErrorDialogInLoginPage(
            errorMessage: 'Anda harus mengisi semua field');
      } else {
        await _userAuthentication();
      }
    }
  }

  Future<void> _userAuthentication() async {
    try {
      await UserAuthenticationRequest(
        name: userData['name'],
        password: userData['password'],
      ).post();
    } catch (error) {
      await showErrorDialogInLoginPage(errorMessage: '$error');
      return;
    }
    await Global.changeAppPage();
  }
}

final loginBloc = LoginBloc();
