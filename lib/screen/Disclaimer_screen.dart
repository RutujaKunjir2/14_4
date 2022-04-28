import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:url_launcher/url_launcher.dart';

class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // return MaterialApp(
    //   home:
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back),
        ),
        backgroundColor: Color(0xffFCD800),
        title: Text("Disclaimer",
            style: const TextStyle(
                color: Color(0xff000000), fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
          child: ConstrainedBox(
              constraints: BoxConstraints(),
              child: Center(
                  child: Column(
                children: <Widget>[
                  Container(
                    alignment: Alignment.centerLeft,
                    //padding: const EdgeInsets.all(15),
                    padding: EdgeInsets.fromLTRB(20, 15, 20, 5),
                    child: RichText(
                      text: TextSpan(
                          style: new TextStyle(
                            fontSize: 16.0,
                            color: Colors.black,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                                text:
                                    "The information contained in this app is for general information purposes only. The information is provided by "),
                            TextSpan(
                                text:
                                    "ConnectEarth Children For Environment LLP",
                                style:
                                    new TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(
                                text:
                                    " and while we endeavour to keep the information up-to-date and correct, any reliance you place on such information is therefore strictly at your own risk."),
                          ]),
                    ),
                    // child:
                    // Text(
                    //   "The information contained in this app is for general information purposes only. The information is provided by ConnectEarth Children For Environment LLP and while we endeavour to keep the information up-to-date and correct, any reliance you place on such information is therefore strictly at your own risk.In no event will we be liable for any loss or damage including without limitation, indirect or consequential loss or damage, or any loss or damage whatsoever arising from loss of data or profits arise out of, or in connection with, the use of this app",
                    //   style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    // )
                  ),
                  Container(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.fromLTRB(20, 5, 20, 5),
                    child: RichText(
                      text: TextSpan(
                          style: new TextStyle(
                            fontSize: 16.0,
                            color: Colors.black,
                          ),
                          children: <TextSpan>[
                            new TextSpan(
                                text:
                                    "In no event will we be liable for any loss or damage including without limitation, indirect or consequential loss or damage, or any loss or damage whatsoever arising from loss of data or profits arise out of, or in connection with, the use of this app."),
                          ]),
                    ),
                  ),
                  Container(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.fromLTRB(20, 5, 20, 5),
                    child: new RichText(
                      text: new TextSpan(
                          style: new TextStyle(
                            fontSize: 16.0,
                            color: Colors.black,
                          ),
                          children: <TextSpan>[
                            new TextSpan(
                                text:
                                    "Every effort is made to keep the app up and running smoothly. However, "),
                            new TextSpan(
                                text:
                                    "ConnectEarth Children For Environment LLP",
                                style:
                                    new TextStyle(fontWeight: FontWeight.bold)),
                            new TextSpan(
                                text:
                                    " takes no responsibility for, and will not be liable for, the app being temporarily unavailable due to technical issues beyond our control.")
                          ]),
                    ),
                  ),
                  Container(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.fromLTRB(20, 5, 20, 5),
                    child: new RichText(
                      text: new TextSpan(
                          style: new TextStyle(
                            fontSize: 16.0,
                            color: Colors.black,
                          ),
                          children: <TextSpan>[
                            new TextSpan(
                                text: "Email: ",
                                style:
                                    new TextStyle(fontWeight: FontWeight.bold)),
                            new TextSpan(
                                text: "contact@childrenforenvironment.com",
                                style: TextStyle(
                                  color: Colors.green,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () async {
                                    try {
                                      final Email email = Email(
                                        body: '',
                                        subject: '',
                                        recipients: [
                                          'contact@childrenforenvironment.com'
                                        ],
                                        cc: [],
                                        bcc: [],
                                        attachmentPaths: [],
                                        isHTML: false,
                                      );

                                      await FlutterEmailSender.send(email);
                                    } on PlatformException catch (err) {
                                      print("PlatformException : " +
                                          err.toString());
                                    } catch (err) {
                                      print("new : " + err.toString());
                                    }
                                  })
                          ]),
                    ),
                  ),
                  Container(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.fromLTRB(20, 5, 20, 5),
                    //padding: const EdgeInsets.all(10),
                    child: new RichText(
                      text: new TextSpan(
                          style: new TextStyle(
                            fontSize: 16.0,
                            color: Colors.black,
                          ),
                          children: <TextSpan>[
                            new TextSpan(
                                text: "Website: ",
                                style:
                                    new TextStyle(fontWeight: FontWeight.bold)),
                            new TextSpan(
                                text: "https://childrenforenvironment.com",
                                style: TextStyle(
                                    color: Colors.green,
                                    decoration: TextDecoration.underline),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () async {
                                    if (await canLaunch(
                                        "https://childrenforenvironment.com")) {
                                      //await launch(url, forceWebView: true);
                                      await launch(
                                          "https://childrenforenvironment.com");
                                    } else {
                                      throw 'Could not launch ';
                                    }
                                  })
                          ]),
                    ),
                    // child: const Text(
                    //   "Website: https://childrenforenvironment.com",
                    //   style: TextStyle(fontSize: 14),
                    // )
                  ),
                ],
              )))),
      // ),
    );
  }
}
