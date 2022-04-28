import 'dart:async';

import 'package:CFE/Networking/networkUtil.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'Dashboard_screen.dart';
import 'PaymentHistory.dart';

class WebViewEx extends StatefulWidget {

  @override
  createState() => _WebViewState();
}

class _WebViewState extends State<WebViewEx> {
  _WebViewState();

  GlobalKey _globalKey = GlobalKey();
  int _stackToView = 1;
  late WebViewController _controll;
  late var timer;

  void _handleLoad(String url) {
    //print("url list : " + url);
    //if (url.toLowerCase().contains("google.com") && url.toLowerCase().contains("status")) {
    if (url.toLowerCase().contains(NetworkUtil.subscribethankyou)) {
      // timer = new Timer.periodic(Duration(seconds: 20), (Timer t) =>
      //     Navigator.of(context).pop()
      // );
      //Navigator.of(context).pop();

      Fluttertoast.showToast(
          msg: 'Successfully Subscribed.',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.SNACKBAR,
          timeInSecForIosWeb: 1,
          backgroundColor: Color(0xff69F0AE),
          textColor: Color(0xff19442C),
          fontSize: 16.0);

      //Navigator.of(context).pop();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => const Dashboard(),
        ),
            (route) => false,
      );

      //Fluttertoast.showToast(msg: "Successfully Subscribed");
    } else if (url.toLowerCase().contains("failed")) {

      Fluttertoast.showToast(
          msg: 'Transaction failed.Please try again!',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.SNACKBAR,
          timeInSecForIosWeb: 1,
          backgroundColor: Color(0xffE74C3C),
          textColor: Colors.white,
          fontSize: 16.0);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => const Dashboard(),
        ),
            (route) => false,
      );

      //Navigator.of(context).pop();

      //Fluttertoast.showToast(msg: "Please try again!");
    }
    //}

    setState(() {
      _stackToView = 0;
    });
  }

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
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => const Dashboard(),
                    ),
                        (route) => false,
                  );
                },
                icon: Icon(Icons.arrow_back),
              ),
              backgroundColor: Color(0xffFCD800),
              title: Text("Payment",
                  style: const TextStyle(
                      color: Color(0xff000000), fontWeight: FontWeight.bold)),
              iconTheme: IconThemeData(color: Colors.black),
              actions: <Widget>[
                Padding(
                    padding: EdgeInsets.only(right: 20.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (BuildContext context) => PaymentHistory(),
                          ),
                        );
                      },
                      child: Icon(
                        Icons.history,
                        size: 26.0,
                      ),
                    )),
              ],
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
                              NetworkUtil.baseUrl + NetworkUtil.subscribe,
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

  Future<bool> _onBack() async {

    print("back button clicked");
    var value = await _controll.canGoBack(); // check webview can go back

    if (value) {
      _controll.goBack(); // perform webview back operation

      return false;
    } else {

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => const Dashboard(),
        ),
            (route) => false,
      );

      return true;
    }
  }
}
