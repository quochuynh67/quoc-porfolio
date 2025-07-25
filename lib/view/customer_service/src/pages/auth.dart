import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_login/flutter_login.dart';
import 'package:flutter_supabase_chat_core/flutter_supabase_chat_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {

  @override
  Widget build(BuildContext context) => FlutterLogin(
    logo: const AssetImage('assets/images/quoc_logo.png'),
    navigateBackAfterRecovery: true,
    additionalSignupFields: [
      UserFormField(
        keyName: 'first_name',
        displayName: 'First name',
        fieldValidator: (value) {
          if (value == null || value == '') return 'Required';
          return null;
        },
      ),
      UserFormField(
        keyName: 'last_name',
        displayName: 'Last name',
        fieldValidator: (value) {
          if (value == null || value == '') return 'Required';
          return null;
        },
      ),
    ],
    passwordValidator: (value) {
      if (value!.isEmpty) {
        return 'Password is empty';
      }
      return null;
    },
    onLogin: (loginData) async {
      try {
        await Supabase.instance.client.auth.signInWithPassword(
          email: loginData.name,
          password: loginData.password,
        );
      } catch (e) {
        return e.toString();
      }
      return null;
    },
    onSignup: (signupData) async {
      try {
        final response = await Supabase.instance.client.auth.signUp(
          email: signupData.name,
          password: signupData.password!,
        );
        await SupabaseChatCore.instance.updateUser(
          types.User(
            firstName: signupData.additionalSignupData!['first_name'],
            id: response.user!.id,
            lastName: signupData.additionalSignupData!['last_name'],
          ),
        );
      } catch (e) {
        return e.toString();
      }
      return null;
    },
    onSubmitAnimationCompleted: () {
      if(Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      // Navigator.of(context).pushReplacement(
      //   MaterialPageRoute(
      //     builder: (context) => const CSHomePage(),
      //   ),
      // );
    },
    onRecoverPassword: (name) async {
      try {
        await Supabase.instance.client.auth.resetPasswordForEmail(
          name,
        );
      } catch (e) {
        return e.toString();
      }
      return null;
    },
    initialAuthMode: AuthMode.signup,
  );
}
