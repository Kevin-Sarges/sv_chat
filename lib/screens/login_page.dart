import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:new_chat/providers/auth_provider.dart';
import 'package:new_chat/constants/all_constants.dart';

import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    switch (authProvider.status) {
      case Status.authenticateError:
        Fluttertoast.showToast(msg: 'Login falhou !!');
        break;

      case Status.authenticateCanceled:
        Fluttertoast.showToast(msg: 'Login cancelado !!');
        break;

      case Status.authenticated:
        Fluttertoast.showToast(msg: 'Logado com sucesso !!');
        break;
      default:
        break;
    }

    return Scaffold(
      body: Stack(
        children: [
          ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(
              vertical: Sizes.dimen_30,
              horizontal: Sizes.dimen_20,
            ),
            children: [
              vertical50,
              const Text(
                'Bem-Vindo(a) ao SVchat',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: Sizes.dimen_26, fontWeight: FontWeight.bold),
              ),
              vertical30,
              const Text(
                'Faça login para continuar',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: Sizes.dimen_22, fontWeight: FontWeight.w500),
              ),
              vertical50,
              Center(
                child: Image.asset(
                  'assets/images/login.png',
                ),
              ),
              vertical50,
              ElevatedButton(
                onPressed: () async {
                  bool isSuccess = await authProvider.handleGoogleSignIn();

                  if (isSuccess) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomePage(),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  onPrimary: Colors.white,
                  primary: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                ),
                child: Center(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      Image(
                        image: AssetImage('assets/images/google-plus.png'),
                        width: 50,
                        height: 50,
                      ),
                      Spacer(flex: 1,),
                      Text(
                        'Login Google',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Center(
            child: authProvider.status == Status.authenticating
                ? const CircularProgressIndicator(
                    color: AppColors.lightGrey,
                  )
                : const SizedBox.shrink(),
          )
        ],
      ),
    );
  }
}
