import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class UserCreationSuccess extends StatefulWidget {
  const UserCreationSuccess({super.key});

  @override
  State<UserCreationSuccess> createState() => _UserCreationSuccessState();
}

class _UserCreationSuccessState extends State<UserCreationSuccess> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Lottie.asset('assets/lottie/Loading.json', repeat: false),
          Text(
            'Account Created',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
          Text('Redirecting to HomePage'),
          TextButton(onPressed: () {
            Navigator.pushNamed(context, '/user_screen');
          }, child: Text('Temporary Button'))
        ],
      ),
    );
  }
}
