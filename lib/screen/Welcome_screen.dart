import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'CreateAccount_screen.dart';
import 'Login_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //requestStoragePermission();
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            padding: const EdgeInsets.all(25),
            child: const Center(
              child: Image(image: AssetImage('assets/splash_logo.png')),
            )),
        persistentFooterButtons: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                margin:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                width: double.infinity,
                // width: 300.0,
                height: 50.0,
                //margin: const EdgeInsets.only(bottom: 10.0),
                child: OutlinedButton(
                  child: const Text('Create an account'),
                  style: OutlinedButton.styleFrom(
                    primary: Colors.white,
                    backgroundColor: const Color(0xff579515),
                  ),
                  onPressed: () {
                    Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (context) => const CreateAccount()));
                  },
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                width: double.infinity,
                height: 50.0,
                //margin: const EdgeInsets.only(bottom: 30.0),
                child: OutlineButton(
                  child: const Text('I already have an account',
                      style: TextStyle(color: Colors.green)),
                  borderSide: const BorderSide(
                    color: Colors.green,
                    style: BorderStyle.solid,
                    width: 1.0,
                  ),
                  onPressed: () {
                    Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (context) => const LoginScreen()));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> requestStoragePermission() async {

    final serviceStatus = await Permission.storage.isGranted;

    bool isStoragePermission = serviceStatus == ServiceStatus.enabled;

    final status = await Permission.storage.request();

    if (status == PermissionStatus.granted) {
      print('Permission Granted');
    } else if (status == PermissionStatus.denied) {
      print('Permission denied');
    } else if (status == PermissionStatus.permanentlyDenied) {
      print('Permission Permanently Denied');
      await openAppSettings();
    }
  }

}