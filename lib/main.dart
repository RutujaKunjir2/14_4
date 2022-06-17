import 'dart:async';
import 'package:CFE/Networking/networkUtil.dart';
import 'package:CFE/screen/Dashboard_screen.dart';
import 'package:CFE/screen/Login_screen.dart';
import 'package:CFE/services/storage.dart';
import 'package:device_info/device_info.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:store_redirect/store_redirect.dart';
import 'dart:io' show File, Platform;
import 'screen/Info_screen.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:navigation_history_observer/navigation_history_observer.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';


Future<void> main() async{
  // if (isProduction) {
  //   debugPrint = (String message, {int wrapWidth}) {};
  // }
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

  await runZonedGuarded(() async {
    //WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
    runApp(MyApp());
  }, (error, stackTrace) {
    FirebaseCrashlytics.instance.recordError(error, stackTrace);
  });

  //runApp(MyApp());
}

class MyApp extends StatelessWidget {

  // Future<void> _initializeFirebase() async {
  //   await Firebase.initializeApp();
  //   await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  // }

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'Splash Screen',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: MyHomePage(),
      navigatorObservers: [NavigationHistoryObserver()],
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  NetworkUtil _netUtil = new NetworkUtil();
  late SharedPreferences prefs;
  String email = '',password = '',Username = '';
  oauth2.AuthorizationCodeGrant? grant;
  oauth2.Client? _client;
  late final file;
  bool? isgoogleLogin;
  late SecureStorage secureStorage;

  @override
  void initState(){
    super.initState();

    getPreferenceData();

  }

  getPreferenceData() async {

    prefs = await SharedPreferences.getInstance();

    secureStorage = await SecureStorage();

    secureStorage.writeSecureData('fbidentifier', '5');
    secureStorage.writeSecureData('fbsecret', "XrbwLuHbZo0XAiKLGOOTdUro7IBj2S1uY8VkP38f");

    secureStorage.writeSecureData('gidentifier', '4');
    secureStorage.writeSecureData('gsecret', "c69iHuyrkPvFuKyYrOvTGkraU6jL5R2vaNxmVFzX");

    bool? isLogin = await prefs.getBool('isLogin');
    bool? isSocialLogin = await prefs.getBool('isSocialLogin');
    isgoogleLogin = await prefs.getBool('isgoogleLogin');
    bool? isAdult = await prefs.getBool('isAdult');

    if(isAdult != null){
      NetworkUtil.isAdult = isAdult;
    }
    final DeviceInfoPlugin deviceInfoPlugin = new DeviceInfoPlugin();

    try {
      if (Platform.isAndroid) {
        var build = await deviceInfoPlugin.androidInfo;
        NetworkUtil.deviceVersion = build.version.toString();
        NetworkUtil.deviceId = build.androidId;  //UUID for Android
      } else if (Platform.isIOS) {
        var data = await deviceInfoPlugin.iosInfo;
        NetworkUtil.deviceVersion = data.systemVersion;
        NetworkUtil.deviceId = data.identifierForVendor;  //UUID for iOS
      }
    } on PlatformException {
      print('Failed to get platform version');
    }

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String build = packageInfo.buildNumber;
    NetworkUtil.AppVersion = packageInfo.version.toString();

    //print("AppVersion : " + packageInfo.version);
    //print("isLogin" + " : "+ isLogin.toString() + "isSocialLogin : " + isSocialLogin.toString() + "isgoogleLogin : " + isgoogleLogin.toString());
    if(isLogin != null){

      NetworkUtil.isLogin = isLogin;

      if(isLogin && isSocialLogin != null && !isSocialLogin){
        email = prefs.getString('email')!;
        password = await secureStorage.readSecureData('password');
        //password = prefs.getString('password')!;
        //password = prefs.getString('password')!;

        if(prefs.getString('UserName') != null){
          Username = prefs.getString('UserName')!;
        }

        NetworkUtil.email = email;
        NetworkUtil.UserName = Username;

        bool? isAdult = await prefs.getBool('isAdult');

        if(isAdult != null){
          NetworkUtil.isAdult = isAdult;
        }
      }

      NetworkUtil.isSocialLogin = isSocialLogin!;
    }else{
      NetworkUtil.isLogin = false;
    }

    //print("isLogin" + " : "+ isLogin.toString() + "email :" + email + "pass " + password);

    _netUtil.isConnected().then((internet) {
      if (internet) {
        checkUserLogin();
      } else {
        NetworkUtil.showDialogNoInternet('You are disconnected to the Internet.','Please check your internet connection',context);
      }
    });


  }

  @override
  Widget build(BuildContext context) {
    // return Container(
    //     color: Colors.white,
    //     child: Image(image: AssetImage('assets/cfe_logo_200.png')));

    return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(25),
        child: const Center(
          child: Image(image: AssetImage('assets/splash_logo.png')),
        ),
    );
  }

  checkUserLogin(){

    if(NetworkUtil.isLogin){

      if(NetworkUtil.isSocialLogin){
        //socialLogin();
      }
      else
      {
        if (Platform.isAndroid)
        {
          login(email,password);
        }
        else if (Platform.isIOS)
        {
          refreshToken();
        }

      }

    }else{
      Timer(
          Duration(seconds: 2),
              () =>
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const InfoScreen()))
      );

    }

  }

  void refreshToken() {

    var body = {
      "device_id": ""+NetworkUtil.deviceId,
      "secret": ""+NetworkUtil.secret,
    };

    print("refresh body : " + body.toString());

    _netUtil.post(NetworkUtil.refreshToken,body,true).then((dynamic res) {

      print("refresh res : " +res.toString());

      if(res != null && res["MessageType"] == 1)
      {

        NetworkUtil.token = res["tokens"]["refresh_token"];
        NetworkUtil.isLogin = true;


        if(res["SubscriptionEndDate"] != null){
          NetworkUtil.subscription_end_date = res["SubscriptionEndDate"];
        }

        if(res["subscribed"] == 0){
          NetworkUtil.isSubScribedUser = false;
        }else{
          NetworkUtil.isSubScribedUser = true;
        }

        prefs.setString('token', res["tokens"]["refresh_token"]);
        prefs.setBool('isLogin', true);


        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const Dashboard()));

        //return res["token"];

      }
      else if(res != null && res["MessageType"] == -1){

        showAlertDialog(context,res["Message"]);

      }else if(res != null && res["MessageType"] == 0){

        Fluttertoast.showToast(
            msg: res["Message"],
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.SNACKBAR,
            timeInSecForIosWeb: 1,
            backgroundColor: Color(0xffDA4542),
            textColor: Colors.white,
            fontSize: 16.0
        );

      }else{

        Fluttertoast.showToast(
            msg: 'Something went wrong.',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.SNACKBAR,
            timeInSecForIosWeb: 1,
            backgroundColor: Color(0xffDA4542),
            textColor: Colors.white,
            fontSize: 16.0
        );
        // final snack = SnackBar(behavior: SnackBarBehavior.floating,content: Text(res["Message"]),duration: Duration(seconds: 2),);
        // ScaffoldMessenger.of(context).showSnackBar(snack);

        //return res["Message"];
      }


    }).catchError((e) {
      print(e);
      Fluttertoast.showToast(
          msg: 'Something went wrong.',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.SNACKBAR,
          timeInSecForIosWeb: 1,
          backgroundColor: Color(0xffE74C3C),
          textColor: Colors.white,
          fontSize: 16.0
      );
    });
  }

  void login(String username, String password) {

    var body = {
      "email": username,
      "password": password,
      "deviceId": NetworkUtil.deviceId,
      "Appversion": NetworkUtil.AppVersion
    };

    //print("login body : " + body.toString());

    _netUtil.post(NetworkUtil.getToken,body,false).then((dynamic res) {

      //print(res.toString());

      if(res != null && res["MessageType"] == 1){

        NetworkUtil.token = res["token"];
        NetworkUtil.isLogin = true;
        NetworkUtil.email = username;


        if(res["subscription_end_date"] != null){
          NetworkUtil.subscription_end_date = res["subscription_end_date"];
        }

        if(res["subscribed"] == 0){
          NetworkUtil.isSubScribedUser = false;
        }else{
          NetworkUtil.isSubScribedUser = true;
        }


        prefs.setString('email', username);
        secureStorage.writeSecureData('password', password);
        //prefs.setString('password', password);
        prefs.setString('token', res["token"]);
        prefs.setBool('isLogin', true);


        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const Dashboard()));

        //return res["token"];

      }
      else if(res != null && res["MessageType"] == -1){

        showAlertDialog(context,res["Message"]);

      }else if(res != null && res["MessageType"] == 0){

        Fluttertoast.showToast(
            msg: res["Message"],
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.SNACKBAR,
            timeInSecForIosWeb: 1,
            backgroundColor: Color(0xffDA4542),
            textColor: Colors.white,
            fontSize: 16.0
        );

      }else{

        Fluttertoast.showToast(
            msg: 'Something went wrong.',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.SNACKBAR,
            timeInSecForIosWeb: 1,
            backgroundColor: Color(0xffDA4542),
            textColor: Colors.white,
            fontSize: 16.0
        );
        // final snack = SnackBar(behavior: SnackBarBehavior.floating,content: Text(res["Message"]),duration: Duration(seconds: 2),);
        // ScaffoldMessenger.of(context).showSnackBar(snack);

        //return res["Message"];
      }


    }).catchError((e) {
      print(e);
      Fluttertoast.showToast(
          msg: 'Something went wrong.',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.SNACKBAR,
          timeInSecForIosWeb: 1,
          backgroundColor: Color(0xffE74C3C),
          textColor: Colors.white,
          fontSize: 16.0
      );
    });
  }

  // Progress indicator widget to show loading.
  Widget loadingView() => Center(
    child: CircularProgressIndicator(
      backgroundColor: Colors.red,
    ),
  );

  // View to empty data message
  Widget noDataView(String msg) => Center(
    child: Text(
      msg,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
    ),
  );


  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    //print("path : " + path);
    return File('$path/credentials.json');
  }

  showAlertDialog(BuildContext context,String msg) async{

    NetworkUtil.isLogin = false;
    NetworkUtil.isSocialLogin = false;
    NetworkUtil.isSubScribedUser = false;
    NetworkUtil.isAdult = false;
    NetworkUtil.subscription_end_date = '';

    prefs.setBool('isLogin', false);
    await secureStorage.deleteSecureData("password");
    prefs.clear();
    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("Cancel"),
      onPressed: () {
        SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      },
    );
    Widget continueButton = TextButton(
      child: Text("ok"),
      onPressed: () {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const InfoScreen()));
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("CFE"),
      content: Text(msg),
      actions: [
        //cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  // void socialLogin() async{
  //
  //   file = await _localFile;
  //   var exists = await file.exists();
  //
  //   //print("Credentials exists " + exists.toString());
  //   // If the OAuth2 credentials have already been saved from a previous run, we
  //   // just want to reload them.
  //   if (exists) {
  //
  //     var identifier = "4";//"772154352723-c8nb4u4tudoo48rklm5gt223th3arhfc.apps.googleusercontent.com";//"584735013765-i9jecsd8c66ukoor0qc7cj76mpd8u0rb.apps.googleusercontent.com";
  //     var secret = "c69iHuyrkPvFuKyYrOvTGkraU6jL5R2vaNxmVFzX";//"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";//"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";
  //
  //     if(isgoogleLogin!){
  //
  //       identifier = await secureStorage.readSecureData('gidentifier');
  //       secret = await secureStorage.readSecureData('gsecret');
  //
  //     }else{
  //
  //       identifier = await secureStorage.readSecureData('fbidentifier');
  //       secret = await secureStorage.readSecureData('fbsecret');
  //
  //     }
  //
  //     var credentials =
  //     oauth2.Credentials.fromJson(await file.readAsString());
  //     var client = oauth2.Client(
  //         credentials, identifier: identifier, secret: secret);
  //     await file.writeAsString(client.credentials.toJson());
  //
  //     //var as = client.credentials.toJson();
  //     //print("credentials" + client.credentials.accessToken);
  //
  //     NetworkUtil.token = client.credentials.accessToken;
  //     NetworkUtil.isLogin = true;
  //     NetworkUtil.isSocialLogin = true;
  //
  //     prefs.setString('token', client.credentials.accessToken);
  //     prefs.setBool('isLogin', true);
  //     prefs.setBool('isSocialLogin', true);
  //
  //     if(isgoogleLogin!){
  //       prefs.setBool('isgoogleLogin', true);
  //       prefs.setBool('isfbLogin', false);
  //     }else{
  //       prefs.setBool('isfbLogin', true);
  //       prefs.setBool('isgoogleLogin', false);
  //     }
  //
  //
  //     Navigator.pushAndRemoveUntil(
  //       context,
  //       MaterialPageRoute(
  //         builder: (BuildContext context) => const Dashboard(),
  //       ),
  //           (route) => false,
  //     );
  //   }else{
  //
  //     Navigator.push(
  //         context,
  //         MaterialPageRoute(
  //             builder: (context) => const LoginScreen()));
  //
  //   }
  //
  // }
}


