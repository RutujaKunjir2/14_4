import 'dart:convert';
import 'package:CFE/Networking/networkUtil.dart';
import 'package:CFE/screen/Welcome_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'BuildProfile_screen.dart';
import 'Login_screen.dart';

class ResetPassword extends StatefulWidget {

  String email;

  ResetPassword({Key? key,required this.email}) : super(key: key);

  @override
  State<ResetPassword> createState() => ResetPassword_screen(email : this.email);
}

class ResetPassword_screen extends State<ResetPassword> {

  bool _isHidden = true;
  bool _submit = false;
  String email;
  late SharedPreferences prefs;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController conformpasswordController = TextEditingController();

  NetworkUtil _netUtil = new NetworkUtil();
  late String password = '';
  final passwordValidator = MultiValidator([
    RequiredValidator(errorText: 'Password is required'),
    MinLengthValidator(8, errorText: 'Password must be at least 8 digits long'),
    PatternValidator(r'(?=.*?[#?!@$%^&*-])', errorText: 'Passwords must have at least one special character')
  ]);

  ResetPassword_screen({required this.email});

  @override
  void initState() {
    super.initState();

    setState(() {
      emailController.text = email;
    });

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
        title: Text("Reset Password",style: const TextStyle(color: Color(0xff000000),fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: ModalProgressHUD(child:Padding(
        padding: EdgeInsets.all(10),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            children: <Widget>[
              // Container(
              //   width: 208,
              //   height: 228,
              //   alignment: Alignment.center,
              //   //padding: EdgeInsets.all(10),
              //   padding: EdgeInsets.fromLTRB(10, 10, 10, 5),
              //   child: Image(image: AssetImage('assets/earth_people.png')),
              // ),
              Container(
                padding: EdgeInsets.all(10),
                child: TextFormField(
                  controller: emailController,
                  readOnly: true,
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
              Container(
                padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: TextFormField(
                  obscureText: _isHidden,
                  controller: passwordController,
                  decoration: InputDecoration(
                    isDense: true, // Added this
                    contentPadding: EdgeInsets.all(17),
                    border: OutlineInputBorder(
                      borderSide: const BorderSide(
                          color: Color(0xff6AA6A4), width: 0.0),
                    ),
                    labelText: 'New Password',
                    suffix: InkWell(
                      onTap: _togglePasswordView,
                      child: Icon(
                          _isHidden
                              ? Icons.visibility
                              : Icons.visibility_off,color: Theme.of(context).primaryColorDark
                      ),
                    ),
                  ),
                  onChanged: (val) => password = val,
                  validator: passwordValidator,
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: TextFormField(
                  obscureText: true,
                  controller: conformpasswordController,
                  decoration: InputDecoration(
                    isDense: true, // Added this
                    contentPadding: EdgeInsets.all(17),
                    border: OutlineInputBorder(
                      borderSide: const BorderSide(
                          color: Color(0xff6AA6A4), width: 0.0),
                    ),
                    labelText: 'Confirm Password',
                  ),
                  validator: (val) => MatchValidator(errorText: 'passwords do not match').validateMatch(val!, password),
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
                child: Text('Reset Password'),
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
                        ResetPassword(emailController.text,passwordController.text,conformpasswordController.text);

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

  void _togglePasswordView() {
    setState(() {
      _isHidden = !_isHidden;
    });
  }

  void ResetPassword(String email, String password,String cnfpassword) {

    var body = {
      //"email": email,
      "password": password,
      "password_confirmation": cnfpassword
    };

    _netUtil.post(NetworkUtil.resetpassword,body,true).then((dynamic res) {

      //print(res.toString());

      setState(() {
        _submit = false;
      });

      if(res != null && res["MessageType"] == 1){

        //NetworkUtil.token = res["token"];
        //NetworkUtil.email = email;
        //NetworkUtil.isAdult = isSkipChild;

        //prefs.setString('password',password);
        //prefs.setString('UserName', name);
        //NetworkUtil.isLogin = true;

        Fluttertoast.showToast(
            msg: res["Message"],
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.SNACKBAR,
            timeInSecForIosWeb: 1,
            backgroundColor: Color(0xff69F0AE),
            textColor: Color(0xff19442C),
            fontSize: 16.0
        );

        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => WelcomeScreen()
            ),
            ModalRoute.withName("/")
        );

        // Navigator.pushReplacement(
        //     context,
        //     CupertinoPageRoute(
        //         builder: (context) => const LoginScreen()));

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
}