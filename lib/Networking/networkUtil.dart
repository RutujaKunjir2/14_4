import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity/connectivity.dart';
import 'package:http/http.dart';

class NetworkUtil {
  // next three lines makes this class a Singleton
  static NetworkUtil _instance = new NetworkUtil.internal();
  NetworkUtil.internal();
  factory NetworkUtil() => _instance;

  static String StripePublishablekey = "";
  //static String baseUrl = "http://cfe.carvingit.com/";
  static String baseUrl = "https://www.childrenforenvironment.com/";
  static String getToken = "api/user/get-token";
  static String registerUser = "api/user/register";
  static String createUserProfile = "api/saveprofile";
  static String getCategories = "api/categories";
  static String getUserDetail = "api/user";
  static String getProfile = "api/account/profile";
  static String forgotPassword = "forgot-password";
  static String getCategoriesdetail = "";
  static String getAppSearch = "";
  static String getFavoriteList = "";
  static String getFastFactList = "";
  static String getFAQs = "";
  static String AddToFavorite = "";
  static String RemoveFromFavorite = "";
  static String getFeedList = "";
  static String getGalleryList = "";
  static String getPaymentIntent = "api/subscription/intent";
  static String subscriptionSuccess = ""; //"api/subscription/success";
  static String getPlans = "api/subscription/plans";
  static String createSubscription = "api/subscription/create";
  static String requestotp = "api/request_otp";
  static String verifyotp = "api/verify_otp";
  static String resetpassword = "api/reset_password";
  static String subscribe = "subscribe";
  static String payments = "payments";
  static String subscribethankyou = "/subscribe-thankyou";

  static String token = '';
  static String deviceId = "";
  static String deviceVersion = '';
  static String AppVersion = "1.0.0";
  static String UserName = '';
  static String email = '';
  static bool isAdult = false;
  static bool isLogin = false;
  static bool isSocialLogin = false;
  static bool isSubScribedUser = true;
  static String subscription_end_date = '';

  final JsonDecoder _decoder = new JsonDecoder();

  Future<bool> isConnected() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile) {
      return true;
    } else if (connectivityResult == ConnectivityResult.wifi) {
      return true;
    }
    return false;
  }

  Future<dynamic> get(String url, bool isHeader) async {
    //print("url get:" + baseUrl + url);

    try {
      //var response = await Http.get("YourUrl").timeout(const Duration(seconds: 3));
      var response = await http
          .get(Uri.parse(baseUrl + url),
              headers: isHeader
                  ? {
                      'Accept': 'application/json',
                      'Authorization': 'Bearer ' + token
                    }
                  : {})
          .timeout(Duration(seconds: 10));

      //print("response" + response.body);

      final String res = response.body;
      final int statusCode = response.statusCode;
      if (statusCode < 200 || statusCode > 401 || json == null) {
        throw new Exception("Error while fetching data");
      }

      return _decoder.convert(res);
    } on TimeoutException catch (e) {
      print('Timeout');
    } on Error catch (e) {
      print('Error: $e');
    }

    // return http.get(Uri.parse(baseUrl + url),headers: isHeader ? {'Accept' : 'application/json',
    //   'Authorization' : 'Bearer ' + token} : {}).then((http.Response response) {
    //   final String res = response.body;
    //   final int statusCode = response.statusCode;
    //   print(res.toString() + " " + statusCode.toString());
    //   if (statusCode < 200 || statusCode > 400 || json == null) {
    //     throw new Exception("Error while fetching data");
    //   }
    //   return _decoder.convert(res);
    // });
  }

  Future<dynamic> post(String url, dynamic body, bool isHeader) async {
    try {
      //print('isHeader : ' + isHeader.toString());
      var response = await http
          .post(Uri.parse(baseUrl + url),
              body: body,
              headers: isHeader
                  ? {
                      'Accept': 'application/json',
                      'Authorization': 'Bearer ' + token
                    }
                  : {})
          .timeout(Duration(seconds: 10));
      final String res = response.body;
      //print("response" + response.body + response.statusCode.toString());
      final int statusCode = response.statusCode;
      if (statusCode < 200 || statusCode > 450 || json == null) {
        throw new Exception("Error while fetching data");
      }
      return _decoder.convert(res);
    } on TimeoutException catch (e) {
      print('Timeout');
    } on Error catch (e) {
      print('Error: $e');
    }

    // return http
    //     .post(Uri.parse(baseUrl + url), body: body, headers: isHeader ? {'Accept' : 'application/json',
    //   'Authorization' : 'Bearer ' + token} : {})
    //     .then((http.Response response) {
    //   final String res = response.body;
    //   final int statusCode = response.statusCode;
    //   print(res.toString() + " " + statusCode.toString());
    //
    //   if (statusCode < 200 || statusCode > 400 || json == null) {
    //     //throw new Exception("Error while fetching data");
    //     return _decoder.convert(res);
    //   }
    //   return _decoder.convert(res);
    // });
  }

  Future<Response> postRequest(String url, dynamic body, bool isHeader) async {
    var response;
    try {
      response = await http
          .post(Uri.parse(baseUrl + url),
              body: body,
              headers: isHeader
                  ? {
                      'Accept': 'application/json',
                      'Authorization': 'Bearer ' + token
                    }
                  : {})
          .timeout(Duration(seconds: 10));
      // final String res = response.body;
      // final int statusCode = response.statusCode;
      // if (statusCode < 200 || statusCode > 400 || json == null) {
      //   throw new Exception("Error while fetching data");
      // }
      return response;
    } on TimeoutException catch (e) {
      print('Timeout');
    } on Error catch (e) {
      print('Error: $e');
    }

    return response;
  }

  static showDialogNoInternet(
      String title, String content, BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: new Text(title),
              content: new Text(content),
              actions: <Widget>[
                new FlatButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _instance.isConnected().then((internet) {
                        if (!internet) {
                          NetworkUtil.showDialogNoInternet(
                              'You are disconnected to the Internet.',
                              'Please check your internet connection',
                              context);
                        }
                      });
                    },
                    child: new Text("Close"))
              ]);
        });
  }
}
