import 'dart:async';

import 'package:CFE/Networking/networkUtil.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'Dashboard_screen.dart';

class PaymentHistory extends StatefulWidget {

  @override
  createState() => PaymentHistoryScreen();
}

class PaymentHistoryScreen extends State<PaymentHistory> {

  GlobalKey _globalKey = GlobalKey();
  int _stackToView = 1;
  late WebViewController _controll;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: _onBack,
        child: Scaffold(
            key: _globalKey,
            appBar: AppBar(
              automaticallyImplyLeading: true,
              leading: IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: Icon(Icons.arrow_back),
              ),
              backgroundColor: Color(0xffFCD800),
              title: Text("Payment History",
                  style: const TextStyle(
                      color: Color(0xff000000), fontWeight: FontWeight.bold)),
              iconTheme: IconThemeData(color: Colors.black),
            ),
            body: IndexedStack(
              index: _stackToView,
              children: [
                Column(
                  children: <Widget>[
                    Expanded(
                      child: WebView(
                        //initialUrl: URL,
                        javascriptMode: JavascriptMode.unrestricted,
                        onWebViewCreated:
                            (WebViewController webViewController) {
                          //webViewController.clearCache();
                          Map<String, String> headers = {
                            "Authorization": "Bearer " + NetworkUtil.token
                          };
                          //print("header" + headers.toString());
                          webViewController.loadUrl(
                              NetworkUtil.baseUrl + NetworkUtil.payments,
                              headers: headers);
                          _controll = webViewController;
                        },
                        onPageFinished: _handleLoad,
                        navigationDelegate: (NavigationRequest request) {
                          //print('allowing navigation to $request');
                          return NavigationDecision.navigate;
                        },
                      ),
                    ),
                  ],
                ),
                Container(
                  color: Colors.white,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ],
            )));
  }

  void _handleLoad(String url) {
    setState(() {
      _stackToView = 0;
    });
  }

  Future<bool> _onBack() async {

    Navigator.of(context).pop();

    return true;
  }
}
