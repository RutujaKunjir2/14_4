import 'dart:async';
import 'dart:convert';
import 'package:CFE/Networking/networkUtil.dart';
import 'package:CFE/services/storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'BuildProfile_screen.dart';

class CreateAccount extends StatefulWidget {
  const CreateAccount({Key? key}) : super(key: key);

  @override
  State<CreateAccount> createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {

  bool _isHidden = true;
  bool _submit = false;
  bool isSkipChild = false;
  late SharedPreferences prefs;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController conformpasswordController = TextEditingController();
  late SecureStorage secureStorage;
  NetworkUtil _netUtil = new NetworkUtil();
  late String password = '';
  final passwordValidator = MultiValidator([
    RequiredValidator(errorText: 'Password is required'),
    MinLengthValidator(8, errorText: 'Password must be at least 8 digits long'),
    PatternValidator(r'(?=.*?[#?!@$%^&*-])', errorText: 'Passwords must have at least one special character')
  ]);

  @override
  void initState() {
    super.initState();
    getPreferenceData();
  }

  getPreferenceData() async {

    secureStorage = await SecureStorage();
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
        title: Text("Create Account",style: const TextStyle(color: Color(0xff000000),fontWeight: FontWeight.bold)),
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
                width: 208,
                height: 228,
                alignment: Alignment.center,
                //padding: EdgeInsets.all(10),
                padding: EdgeInsets.fromLTRB(10, 10, 10, 5),
                child: Image(image: AssetImage('assets/earth_people.png')),
              ),
              Container(
                  alignment: Alignment.topLeft,
                  //padding: EdgeInsets.all(10),
                  padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                  child: Text(
                    'Create an account',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  )),
              Container(
                  alignment: Alignment.topLeft,
                  padding: EdgeInsets.fromLTRB(10, 5, 10, 10),
                  child: Text(
                    'A confirmation email will be sent',
                    style: TextStyle(fontSize: 14),
                  )),
              Container(
                padding: EdgeInsets.all(10),
                child: TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    isDense: true, // Added this
                    contentPadding: EdgeInsets.all(17),
                    border: OutlineInputBorder(
                      borderSide: const BorderSide(
                          color: Colors.lightGreenAccent, width: 0.0),
                    ),
                    labelText: "Parent's Name",
                  ),
                  validator: MultiValidator([
                    RequiredValidator(errorText: "Required"),
                  ]),
                ),
              ),
              Container(
                padding: EdgeInsets.all(10),
                child: TextFormField(
                  controller: emailController,
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
                    labelText: 'Password',
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
              Container(
                  alignment: Alignment.topLeft,
                  padding: EdgeInsets.all(10),
                  child: Text(
                    'Almost done just a few more....',
                    style: TextStyle(fontSize: 14),
                  )),
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
                child: Text('Next'),
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
                        RegisterUser(nameController.text,emailController.text,passwordController.text);

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

  void RegisterUser(String name,String email, String password) {

    var body = {
      "name":name,
      "email": email,
      "password": password
    };

    _netUtil.post(NetworkUtil.registerUser,body,false).then((dynamic res) {

      //print(res.toString());

      setState(() {
        _submit = false;
      });

      if(res != null && res["MessageType"] == 1){

        NetworkUtil.token = res["token"];
        NetworkUtil.UserName = name;
        NetworkUtil.email = email;
        NetworkUtil.isLogin = true;
        NetworkUtil.isSocialLogin = false;
        //NetworkUtil.isAdult = isSkipChild;

        //secureStorage.writeSecureData('password', password);
        //prefs.setString('password',password);
        //prefs.setString('UserName', name);
        //NetworkUtil.isLogin = true;

        prefs.setString('email', email);
        prefs.setString('parent_name', name);
        secureStorage.writeSecureData('password', password);
        //prefs.setString('password', password);
        prefs.setString('token', res["token"]);
        prefs.setBool('isSocialLogin', false);
        prefs.setBool('isLogin', true);


        Fluttertoast.showToast(
            msg: res["Message"],
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.SNACKBAR,
            timeInSecForIosWeb: 1,
            backgroundColor: Color(0xff69F0AE),
            textColor: Color(0xff19442C),
            fontSize: 16.0
        );

        Navigator.push(context,
            CupertinoPageRoute(builder: (context) => BuildProfile(isEdit : true, isFromHome : false , parents_name : name)));

        //return res["token"];

      }else if(res != null && res["MessageType"] == 0){

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
          msg: 'Something went wrong 123.',
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