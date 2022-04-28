import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:CFE/Networking/networkUtil.dart';
import 'package:CFE/screen/Forgot_Password.dart';
import 'package:CFE/services/storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../icons.dart';
import 'BuildProfile_screen.dart';
import 'Dashboard_screen.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:permission_handler/permission_handler.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _submit = false;
  late SharedPreferences prefs;
  NetworkUtil _netUtil = new NetworkUtil();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool _isHidden = true;
  late SecureStorage secureStorage;
  // https://accounts.google.com/o/oauth2/auth  http://cfe.carvingit.com/oauth/authorize
  final authorizationEndpoint =
      Uri.parse("https://www.childrenforenvironment.com/oauth/authorize");
  //final authorizationEndpoint = Uri.parse("https://accounts.google.com/o/oauth2/auth");
  final tokenEndpoint =
      Uri.parse("https://www.childrenforenvironment.com/oauth/token");

  // final identifier = "4";
  // final secret = "c69iHuyrkPvFuKyYrOvTGkraU6jL5R2vaNxmVFzX";

  // final identifier = "5";
  // final secret = "XrbwLuHbZo0XAiKLGOOTdUro7IBj2S1uY8VkP38f";
  //
  // final redirectUrl = Uri.parse("https://www.childrenforenvironment.com/oauth/facebook/callback");
  //final credentialsFile = File("~/.myapp/credentials.json");
  //final _scopes = ['openid','profile','email'];
  File? file;
  oauth2.AuthorizationCodeGrant? grant;
  oauth2.Client? _client;

  Uri? _uri;
  StreamSubscription? _sub;
  //final NavigationHistoryObserver historyObserver = NavigationHistoryObserver();

  @override
  void initState() {
    super.initState();
    getPreferenceData();

    // grant = new oauth2.AuthorizationCodeGrant(
    //     identifier, authorizationEndpoint, tokenEndpoint,
    //     secret: secret);
    //
    // //print("grant" + grant!.tokenEndpoint.toString());
    // _uri = grant!.getAuthorizationUrl(redirectUrl);//,scopes: _scopes,state:generateRandomString(25));
    // initUrlListener();
  }

  String generateRandomString(int len) {
    var r = Random();
    const _chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    return List.generate(len, (index) => _chars[r.nextInt(_chars.length)])
        .join();
  }

  // TO START SOCIAL LOGIN CHECK UNCOMMENT initUrlListener FUNCTION
  // This is used for the callback to the app
  // The url should be registered in AndroidManifest.xml and Info.plist
  void initUrlListener(bool isgoogle) async {
    if (file == null) {
      file = await _localFile;
    }

    try {
      //await getInitialLink();

      _sub = uriLinkStream.listen((Uri? uri) async {
        if (!mounted) return;
        //print('got uri: $uri!.queryParameters');

        try {
          //Use the uri and warn the user, if it is not correct
          var client =
              await grant!.handleAuthorizationResponse(uri!.queryParameters);
          //print('client.credentials : $client.credentials');

          if (client.credentials != null) {
            await file!.writeAsString(client.credentials.toJson());
            setState(() {
              //print('got uri: $uri');

              NetworkUtil.token = client.credentials.accessToken;
              NetworkUtil.isLogin = true;
              NetworkUtil.isSocialLogin = true;

              prefs.setString('token', client.credentials.accessToken);
              prefs.setBool('isLogin', true);
              prefs.setBool('isSocialLogin', true);

              if (isgoogle) {
                prefs.setBool('isgoogleLogin', true);
                prefs.setBool('isfbLogin', false);
              } else {
                prefs.setBool('isfbLogin', true);
                prefs.setBool('isgoogleLogin', false);
              }

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) => const Dashboard(),
                ),
                (route) => false,
              );
            });
          } else {
            Fluttertoast.showToast(
                msg: 'Something went wrong.',
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.SNACKBAR,
                timeInSecForIosWeb: 1,
                backgroundColor: Color(0xffE74C3C),
                textColor: Colors.white,
                fontSize: 16.0);
          }
        } on Exception {
          Fluttertoast.showToast(
              msg: 'Something went wrong. please try again later.',
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.SNACKBAR,
              timeInSecForIosWeb: 1,
              backgroundColor: Color(0xffE74C3C),
              textColor: Colors.white,
              fontSize: 16.0);
        }
      }, onError: (err) {
        if (!mounted) return;
        print('got err: $err');
        // Handle exception by warning the user their action did not succeed
      });
    } on PlatformException {
      print("initialLink");
    } on FormatException {
      print("initialLink");
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // return WillPopScope(
    //     onWillPop: () async{
    //         print("isbackPressed " + historyObserver.history.length.toString());
    //         if(historyObserver.history.length != 1){
    //           //show snackbar
    //           Navigator.pop(context);
    //           return false;
    //         }else{
    //           return true;
    //         }
    //         },
    // child :
    //requestStoragePermission();
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
        title: Text("Login",
            style: const TextStyle(
                color: Color(0xff000000), fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: ModalProgressHUD(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                children: <Widget>[
                  Container(
                    width: 198,
                    height: 218,
                    alignment: Alignment.center,
                    //padding: const EdgeInsets.all(10),
                    padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                    child:
                        const Image(image: AssetImage('assets/login_logo.png')),
                  ),
                  Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.fromLTRB(10, 5, 10, 10),
                      //padding: EdgeInsets.all(10),
                      child: Text(
                        'Login',
                        style: TextStyle(
                            fontSize: 26, fontWeight: FontWeight.bold),
                      )),
                  Container(
                    padding: EdgeInsets.fromLTRB(10, 0, 10, 5),
                    //padding: EdgeInsets.all(10),
                    child: TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          isDense: true, // Added this
                          contentPadding: EdgeInsets.all(17),
                          border: OutlineInputBorder(
                            borderSide: const BorderSide(
                                color: Colors.lightGreenAccent, width: 0.0),
                          ),
                          labelText: 'Email',
                        ),
                        validator:
                            RequiredValidator(errorText: "Email Required")),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                    child: TextFormField(
                        obscureText: _isHidden,
                        controller: passwordController,
                        decoration: InputDecoration(
                          isDense: true, // Added this
                          contentPadding: EdgeInsets.all(15),
                          border: OutlineInputBorder(
                            borderSide: const BorderSide(
                                color: Color(0xff6AA6A4), width: 0.0),
                          ),
                          labelText: 'Password',
                          suffix: InkWell(
                            onTap: _togglePasswordView,
                            child: Icon(
                                _isHidden
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Theme.of(context).primaryColorDark),
                          ),
                        ),
                        validator:
                            RequiredValidator(errorText: "Password Required")),
                  ),
                  Container(
                      height: 70,
                      padding: EdgeInsets.fromLTRB(10, 20, 10, 0),
                      child: RaisedButton(
                        textColor: Colors.white,
                        color: Color(0xff579515),
                        child: Text('Login'),
                        onPressed: () {
                          _netUtil.isConnected().then((internet) {
                            if (internet) {
                              if (_formKey.currentState!.validate()) {
                                setState(() {
                                  _submit = true;
                                });
                                login(nameController.text,
                                    passwordController.text);
                              }
                            } else {
                              NetworkUtil.showDialogNoInternet(
                                  'You are disconnected to the Internet.',
                                  'Please check your internet connection',
                                  context);
                            }
                          });
                        },
                      )),
              Container(
                height: 70,
                padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                child:
                  FlatButton(
                    onPressed: () {
                      Navigator.push(context,
                          CupertinoPageRoute(builder: (context) => ForgotPassword()));
                      //forgotPassword();
                      //forgot password screen
                    },
                    textColor: const Color(0xff202805),
                    child: const Text('Forgot Password',
                        style: TextStyle(
                            fontSize: 16,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold)),
                  ),
                  ),
                  Container(
                    height: 70,
                    padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                    child:
                    FlatButton(
                      onPressed: () {
                        Navigator.push(context,
                            CupertinoPageRoute(builder: (context) => ForgotPassword()));
                        //forgotPassword();
                        //forgot password screen
                      },
                      textColor: const Color(0xff202805),
                      child: Text("V" + NetworkUtil.AppVersion,
                          style: TextStyle(
                              fontSize: 12,
                              //decoration: TextDecoration.underline,
                              fontWeight: FontWeight.normal)),
                    ),
                  ),
                  //Container(
                  //  margin: const EdgeInsets.only(top: 10.0),
                  //child:
                  // Row(
                  //   children: const <Widget>[
                  //     Text('OR',
                  //         style: TextStyle(
                  //             fontSize: 16, fontWeight: FontWeight.bold))
                  //   ],
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  // ),
                  //),
                ],
              ),
            ),
          ),
          inAsyncCall: _submit),
      // persistentFooterButtons: [
      //   Column(
      //     crossAxisAlignment: CrossAxisAlignment.center,
      //     mainAxisAlignment: MainAxisAlignment.end,
      //     children: <Widget>[
      //       Container(
      //         margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      //         width: double.infinity,
      //         height: 35.0,
      //         child: ElevatedButton.icon(
      //           style:
      //               ElevatedButton.styleFrom(primary: const Color(0xff365896)),
      //           icon: const Icon(Customicons.facebook, size: 16),
      //           label: const Text('Login with Facebook'),
      //           onPressed: () => {
      //             // _launchURLApp()
      //             fblogin()
      //           },
      //         ),
      //       ),
      //       Container(
      //         margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      //         width: double.infinity,
      //         height: 35.0,
      //         child: ElevatedButton.icon(
      //           style: ElevatedButton.styleFrom(
      //               shadowColor: const Color(0xffE84D3C),
      //               primary: const Color(0xffE84D3C)),
      //           icon: const Icon(Customicons.google, size: 16),
      //           label: const Text('Login with Google'),
      //           onPressed: () => {
      //             //createClient()
      //             opengoogle()
      //           },
      //         ),
      //       ),
      //     ],
      //   ),
      // ],
    );
    //);
  }

  void _togglePasswordView() {
    setState(() {
      _isHidden = !_isHidden;
    });
  }

  getPreferenceData() async {
    prefs = await SharedPreferences.getInstance();

    secureStorage = await SecureStorage();

    // if (file == null) {
    //   file = await _localFile;
    // }

    //bool? val;
    //bool? val = await file!.exists(); //.then((value) => val = value);
    //print("file exist : " + val.toString());
  }

  // opengoogle() async {
  //   final identifier = await secureStorage.readSecureData('gidentifier');
  //   final secret = await secureStorage.readSecureData('gsecret');
  //
  //   final redirectUrl =
  //       Uri.parse("https://www.childrenforenvironment.com/oauth/callback");
  //
  //   grant = new oauth2.AuthorizationCodeGrant(
  //       identifier, authorizationEndpoint, tokenEndpoint, "true",
  //       secret: secret);
  //
  //   //print("grant" + grant!.tokenEndpoint.toString());
  //   _uri = grant!.getAuthorizationUrl(
  //       redirectUrl); //,scopes: _scopes,state:generateRandomString(25));
  //
  //   //print("_uri " + _uri.toString());
  //   var url = _uri.toString();
  //   if (await canLaunch(url)) {
  //     //await launch(url, forceWebView: true);
  //     await launch(url);
  //   } else {
  //     throw 'Could not launch $url';
  //   }
  //
  //   //initUrlListener(true);
  //
  // }

  Uri addQueryParameters(Uri url, Map<String, String> parameters) =>
      url.replace(
          queryParameters: new Map.from(url.queryParameters)
            ..addAll(parameters));

  forgotPassword() async {
    var forgotpasswordurl = NetworkUtil.baseUrl + NetworkUtil.forgotPassword;

    if (await canLaunch(forgotpasswordurl)) {
      await launch(forgotpasswordurl, forceSafariVC: true, forceWebView: true);
      //await launch(url);
    } else {
      throw 'Could not launch $forgotpasswordurl';
    }
  }

  void login(String username, String password) {
    var body = {
      "email": username,
      "password": password,
      "deviceId": NetworkUtil.deviceId,
      "Appversion": NetworkUtil.AppVersion
    };

    //print("login body : " + body.toString());

    _netUtil.post(NetworkUtil.getToken, body, true).then((dynamic res) {
      //print(res.toString());

      setState(() {
        _submit = false;
      });

      if (res != null && res["MessageType"] == 1) {
        NetworkUtil.token = res["token"];
        NetworkUtil.email = username;
        NetworkUtil.isLogin = true;
        NetworkUtil.isSocialLogin = false;

        if (res["subscription_end_date"] != null) {
          NetworkUtil.subscription_end_date = res["subscription_end_date"];
        }

        if (res["subscribed"] == 0) {
          NetworkUtil.isSubScribedUser = false;
        } else {
          NetworkUtil.isSubScribedUser = true;
        }

        prefs.setString('email', username);
        secureStorage.writeSecureData('password', password);
        //prefs.setString('password', password);
        prefs.setString('token', res["token"]);
        prefs.setBool('isSocialLogin', false);
        prefs.setBool('isLogin', true);

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => const Dashboard(),
          ),
          (route) => false,
        );

      }else if(res != null && res["MessageType"] == -1){

        showAlertDialog(context,res["Message"]);

      } else if (res != null && res["MessageType"] == 0) {

        //print("get token" + res["Message"].toString());

        Fluttertoast.showToast(
            msg: res["Message"],
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.SNACKBAR,
            timeInSecForIosWeb: 1,
            backgroundColor: Color(0xffE74C3C),
            textColor: Colors.white,
            fontSize: 16.0);
      } else {
        Fluttertoast.showToast(
            msg: 'Something went wrong.',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.SNACKBAR,
            timeInSecForIosWeb: 1,
            backgroundColor: Color(0xffE74C3C),
            textColor: Colors.white,
            fontSize: 16.0);
        // final snack = SnackBar(behavior: SnackBarBehavior.floating,content: Text(res["Message"]),duration: Duration(seconds: 2),);
        // ScaffoldMessenger.of(context).showSnackBar(snack);

        //return res["Message"];
      }
    }).catchError((e) {
      setState(() {
        _submit = false;
      });
      print(e);
      Fluttertoast.showToast(
          msg: 'Something went wrong.',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.SNACKBAR,
          timeInSecForIosWeb: 1,
          backgroundColor: Color(0xffE74C3C),
          textColor: Colors.white,
          fontSize: 16.0);
    });
  }

  showAlertDialog(BuildContext context,String msg) async{

    NetworkUtil.isLogin = false;
    NetworkUtil.isSocialLogin = false;
    NetworkUtil.isSubScribedUser = true;
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
        Navigator.pop(context);
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

  // fblogin() async {
  //   final identifier = await secureStorage.readSecureData('fbidentifier');
  //   final secret = await secureStorage.readSecureData('fbsecret');
  //
  //   //print("identifier" + identifier);
  //
  //   final redirectUrl = Uri.parse(
  //       "https://www.childrenforenvironment.com/oauth/facebook/callback");
  //
  //   grant = new oauth2.AuthorizationCodeGrant(
  //       identifier, authorizationEndpoint, tokenEndpoint, 'false',
  //       secret: secret);
  //
  //   //print("grant" + grant!.tokenEndpoint.toString());
  //   _uri = grant!.getAuthorizationUrl(
  //       redirectUrl); //,scopes: _scopes,state:generateRandomString(25));
  //
  //   //print("_uri " + _uri.toString());
  //   var url = _uri.toString();
  //   if (await canLaunch(url)) {
  //     //await launch(url, forceWebView: true);
  //     await launch(url);
  //   } else {
  //     throw 'Could not launch $url';
  //   }
  //
  //   //initUrlListener(false);
  // }

  void RegisterUser(String name, String email, String password) {
    //print(name.toString() + " " + email.toString() + " " + password.toString());

    var body = {
      "name": name,
      "email": email,
      "password": password,
      "isSocial": true.toString()
    };

    _netUtil.post(NetworkUtil.registerUser, body, false).then((dynamic res) {
      //print(res.toString());

      setState(() {
        _submit = false;
      });

      if (res != null && res["MessageType"] == 1) {
        NetworkUtil.token = res["token"];
        NetworkUtil.isLogin = true;

        NetworkUtil.UserName = name;
        NetworkUtil.email = email;

        prefs.setString('UserName', name);
        prefs.setString('email', email);
        secureStorage.writeSecureData('password', password);
        //prefs.setString('password', password);
        prefs.setString('token', res["token"]);
        prefs.setBool('isLogin', true);

        Fluttertoast.showToast(
            msg: res["Message"],
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.SNACKBAR,
            timeInSecForIosWeb: 1,
            backgroundColor: Color(0xff69F0AE),
            textColor: Color(0xff19442C),
            fontSize: 16.0);

        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    BuildProfile(isEdit: false, isFromHome: false, parents_name : name)));

        //return res["token"];

      } else if (res != null && res["MessageType"] == 0) {
        Fluttertoast.showToast(
            msg: res["Message"],
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.SNACKBAR,
            timeInSecForIosWeb: 1,
            backgroundColor: Color(0xffE74C3C),
            textColor: Colors.white,
            fontSize: 16.0);
      } else {
        Fluttertoast.showToast(
            msg: 'Something went wrong.',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.SNACKBAR,
            timeInSecForIosWeb: 1,
            backgroundColor: Color(0xffE74C3C),
            textColor: Colors.white,
            fontSize: 16.0);
      }
    }).catchError((e) {
      setState(() {
        _submit = false;
      });
      print(e);
      Fluttertoast.showToast(
          msg: 'Something went wrong.',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.SNACKBAR,
          timeInSecForIosWeb: 1,
          backgroundColor: Color(0xffE74C3C),
          textColor: Colors.white,
          fontSize: 16.0);
    });
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    //print("path : " + path);
    return File('$path/credentials.json');
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
