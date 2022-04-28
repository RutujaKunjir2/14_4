import 'dart:async';
import 'dart:convert';
import 'package:CFE/Networking/networkUtil.dart';
import 'package:CFE/screen/ResetPassword_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'BuildProfile_screen.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({Key? key}) : super(key: key);

  @override
  State<ForgotPassword> createState() => _ForgotPasswordScreen();
}

class _ForgotPasswordScreen extends State<ForgotPassword> {

  bool _isOtpsend = false;
  bool isEmailDisable = false;
  bool _submit = false;
  late SharedPreferences prefs;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  TextEditingController otpController = TextEditingController();

  NetworkUtil _netUtil = new NetworkUtil();


  @override
  void initState() {
    super.initState();
    getPreferenceData();
  }

  getPreferenceData() async {

    prefs = await SharedPreferences.getInstance();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar : AppBar(
        automaticallyImplyLeading: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back),
        ),
        backgroundColor: Color(0xffFCD800),
        title: Text("Forgot Password",style: const TextStyle(color: Color(0xff000000),fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: ModalProgressHUD(child:Padding(
        padding: EdgeInsets.all(10),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            children: <Widget>[
              Container(
                  alignment: Alignment.topLeft,
                  padding: EdgeInsets.fromLTRB(10, 5, 10, 10),
                  child: Text(
                    'Forgot your password? No problem. Just let us know your email address and we will email you a password reset otp that will allow you to choose a new one.',
                    style: TextStyle(fontSize: 14),
                  )),
              Container(
                padding: EdgeInsets.all(10),
                child: TextFormField(
                  controller: emailController,
                  readOnly: isEmailDisable,
                  decoration: InputDecoration(
                    isDense: true, // Added this
                    contentPadding: EdgeInsets.all(17),
                    border: OutlineInputBorder(
                      borderSide: const BorderSide(
                          color: Colors.lightGreenAccent, width: 0.0),
                    ),
                    labelText: 'Email',
                  ),
                  validator: MultiValidator([
                    RequiredValidator(errorText: "Required"),
                    EmailValidator(errorText: "Please enter a valid email address"),
                  ]),
                ),
              ),
              if(_isOtpsend)
              Container(
                padding: EdgeInsets.all(10),
                child: TextFormField(
                  controller: otpController,
                  inputFormatters: [
                    new LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: InputDecoration(
                    isDense: true, // Added this
                    contentPadding: EdgeInsets.all(17),
                    border: OutlineInputBorder(
                      borderSide: const BorderSide(
                          color: Colors.lightGreenAccent, width: 0.0),
                    ),
                    labelText: "Enter OTP",
                  ),
                  validator: RequiredValidator(errorText: "Required"),
                ),
              ),
            ],
          ),
        ),
      ),inAsyncCall: _submit,

      ),
      persistentFooterButtons: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              width: double.infinity,
              height: 50.0,
              child: OutlinedButton(
                child: Text(_isOtpsend ? "Verify Otp" : "Send OTP"),
                style: OutlinedButton.styleFrom(
                  primary: Colors.white,
                  backgroundColor: Color(0xff579515),
                ),
                onPressed: () {
                  _netUtil.isConnected().then((internet) {
                    if (internet) {
                      if (_formKey.currentState!.validate()) {
                        setState(() {
                          _submit = true;
                        });

                        CheckApiCall(emailController.text,otpController.text);
                        //SendOtp(emailController.text);

                        // Navigator.push(context,
                        //     CupertinoPageRoute(builder: (context) => BuildProfile(isEdit : true, isFromHome : false)));

                      }
                    } else {
                      NetworkUtil.showDialogNoInternet('You are disconnected to the Internet.','Please check your internet connection',context);
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  CheckApiCall(String email,String otp){

    if(!_isOtpsend){
      SendOtp(email);
    }else{
      VerifyOtp(email,otp);
    }

  }

  void SendOtp(String email) {

    var body = {
      "email": email,
    };

    _netUtil.post(NetworkUtil.requestotp,body,true).then((dynamic res) {

      //print(res.toString());

      setState(() {
        _submit = false;
      });

      if(res != null && res["MessageType"] == 1){

        //NetworkUtil.token = res["token"];

        setState(() {
          _isOtpsend = true;
          isEmailDisable = true;
        });


        Fluttertoast.showToast(
            msg: res["Message"],
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.SNACKBAR,
            timeInSecForIosWeb: 1,
            backgroundColor: Color(0xff69F0AE),
            textColor: Color(0xff19442C),
            fontSize: 16.0
        );

        // Navigator.push(context,
        //     CupertinoPageRoute(builder: (context) => BuildProfile(isEdit : true, isFromHome : false , parents_name : name)));

        //return res["token"];

      }else if(res != null && res["MessageType"] == 0){

        //var error = json.encode(res['error']);

        //Map<String, dynamic> jsonData = json.decode(error) as Map<String, dynamic>;

        Fluttertoast.showToast(
            msg: res["Message"],
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.SNACKBAR,
            timeInSecForIosWeb: 1,
            backgroundColor: Color(0xffE74C3C),
            textColor: Colors.white,
            fontSize: 16.0
        );

      }else {


        Fluttertoast.showToast(
            msg: 'Something went wrong.',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.SNACKBAR,
            timeInSecForIosWeb: 1,
            backgroundColor: Color(0xffE74C3C),
            textColor: Colors.white,
            fontSize: 16.0
        );

      }

      // Navigator.pushReplacement(context,
      //     CupertinoPageRoute(builder: (context) => const BuildProfile()));
      //
      // return res["token"];

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
          fontSize: 16.0
      );
    });
  }

  void VerifyOtp(String email,String otp) {

    var body = {
      "email": email,
      "otp": otp
    };

    _netUtil.post(NetworkUtil.verifyotp,body,true).then((dynamic res) {

      //print(res.toString());

      setState(() {
        _submit = false;
      });

      if(res != null && res["MessageType"] == 1){

        NetworkUtil.token = res["access_token"];

        Fluttertoast.showToast(
            msg: res["Message"],
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.SNACKBAR,
            timeInSecForIosWeb: 1,
            backgroundColor: Color(0xff69F0AE),
            textColor: Color(0xff19442C),
            fontSize: 16.0
        );

        Navigator.pushReplacement(context,
            CupertinoPageRoute(builder: (context) => ResetPassword(email: email)));

        //return res["token"];

      }else if(res != null && res["MessageType"] == 0){

        //var error = json.encode(res['error']);

        //Map<String, dynamic> jsonData = json.decode(error) as Map<String, dynamic>;

        Fluttertoast.showToast(
            msg: res["Message"],
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.SNACKBAR,
            timeInSecForIosWeb: 1,
            backgroundColor: Color(0xffE74C3C),
            textColor: Colors.white,
            fontSize: 16.0
        );

      }else {


        Fluttertoast.showToast(
            msg: 'Something went wrong.',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.SNACKBAR,
            timeInSecForIosWeb: 1,
            backgroundColor: Color(0xffE74C3C),
            textColor: Colors.white,
            fontSize: 16.0
        );

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
          fontSize: 16.0
      );
    });
  }
}