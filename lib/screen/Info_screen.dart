import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'Welcome_screen.dart';


class InfoScreen extends StatelessWidget {
  const InfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView( child: ConstrainedBox( constraints: BoxConstraints(),
            child :Center(
            child: Column(
              children: <Widget>[
                Container(
                  width: 377.0,
                  height: 182.0,
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.only(top: 25.0),
                  child: const Center(
                    child: Image(image: AssetImage('assets/parents_info.png')),
                  ),
                ),
                Container(
                    alignment: Alignment.centerLeft,
                    //padding: const EdgeInsets.all(15),
                    padding: EdgeInsets.fromLTRB(20, 5, 20, 5),
                    child: const Text(
                      'Dear Children, Students, Parents and Teachers,',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    )),
                Container(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.fromLTRB(20, 5, 20, 5),
                    child: const Text(
                      'Welcome to Children For Environment. Welcome to the natural world.',
                      style: TextStyle(fontSize: 14),
                    )),
                Container(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.fromLTRB(20, 5, 20, 5),
                    child: const Text(
                      "Our endeavor is to make children appreciate the ethos of Teleology - 'Everything in nature has a purpose.'",
                      style: TextStyle(fontSize: 14),
                    )),
                Container(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.fromLTRB(20, 5, 20, 5),
                    //padding: const EdgeInsets.all(10),
                    child: const Text(
                      "Only when they know, will they connect. And connecting with Earth, our only home, is a necessity. It is not a matter of interest.",
                      style: TextStyle(fontSize: 14),
                    )),
                Container(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.fromLTRB(20, 5, 20, 5),
                    //padding: const EdgeInsets.all(10),
                    child: const Text(
                      "There is turmoil in our home. Our objective is to help children reconnect with nature so they grow up as adults who can make decisions in its best interest.This app will facilitate a leisurely unfettered exploration of nature, wildlife, natural systems and processes.",
                      style: TextStyle(fontSize: 14),
                    )),
                Container(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.fromLTRB(20, 5, 20, 5),
                    //padding: const EdgeInsets.all(10),
                    child: const Text(
                      "No pressure to learn. No exams to write. No classroom walls. No curriculum.",
                      style: TextStyle(fontSize: 14),
                    )),
                Container(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.fromLTRB(20, 5, 20, 5),
                    //padding: const EdgeInsets.all(10),
                    child: const Text(
                      "This app, with an intuitive workflow, has been designed to promote reading and avoids visual wizardry.",
                      style: TextStyle(fontSize: 14),
                    )),
                Container(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.fromLTRB(20, 5, 20, 5),
                    //padding: const EdgeInsets.all(10),
                    child: const Text(
                      "Please join us in discovering the many stories, facts, figures and nuances that make up our beautiful planet.",
                      style: TextStyle(fontSize: 14),
                    )),
              ],
            )))),
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
                  child: const Text('Proceed'),
                  style: OutlinedButton.styleFrom(
                    primary: Colors.white,
                    backgroundColor: const Color(0xff579515),
                  ),
                  onPressed: () {
                    // FirebaseCrashlytics.instance.log("It's a bug");
                    // FirebaseCrashlytics.instance.crash();
                    Navigator.pushReplacement(
                        context,
                        CupertinoPageRoute(
                            builder: (context) => const WelcomeScreen()));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}