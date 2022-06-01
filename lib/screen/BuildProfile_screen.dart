import 'dart:async';
import 'dart:convert';

import 'package:CFE/Networking/networkUtil.dart';
import 'package:CFE/screen/Dashboard_screen.dart';
import 'package:CFE/screen/Login_screen.dart';
import 'package:CFE/screen/Welcome_screen.dart';
import 'package:CFE/services/storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

import '../icons.dart';


class BuildProfile extends StatefulWidget {

  bool isEdit;
  bool isFromHome;
  String parents_name;

  BuildProfile({Key? key,required this.isEdit,required this.isFromHome, required this.parents_name}) : super(key: key);

  @override
  State<BuildProfile> createState() => _BuildProfileState(isEdit : this.isEdit,isFromHome : this.isFromHome, parents_name : this.parents_name);
}

class _BuildProfileState extends State<BuildProfile> {

  bool isEdit;
  bool isFromHome;
  String parents_name;

  _BuildProfileState({required this.isEdit, required this.isFromHome,required this.parents_name});

  NetworkUtil _netUtil = new NetworkUtil();
  bool _submit = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String date = "";
  DateTime selectedDate = DateTime.now();
  String? classvalue = 'Select Class';
  int profile_id = 0;
  String? userId;

  TextEditingController nameController = TextEditingController();
  TextEditingController parentnameController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController schoolController = TextEditingController();
  TextEditingController classcontroller = new TextEditingController();
  TextEditingController cityController = new TextEditingController();
  TextEditingController parentemailController = new TextEditingController();
  TextEditingController parentmobileController = new TextEditingController();
  late SecureStorage secureStorage;

  TextEditingController classController = TextEditingController();

  var items = ['Select Class','1','2','3','4','5','6','7','8','9','10'];
  late SharedPreferences prefs;
  bool isSkipChild = false;
  bool isSkipChildChanged = false;
  String password = '';

  @override
  void initState() {

    super.initState();

    getPreferenceData();

  }

  getPreferenceData() async {

    prefs = await SharedPreferences.getInstance();

    secureStorage = await SecureStorage();

    userId = prefs.getString("UserId");

    if(await secureStorage.readSecureData('password') != null){
      password = await secureStorage.readSecureData('password');
    }

    if(isFromHome){

      setState(() {
        isEdit = false;
      });
      getUserData(userId!);

    }

  }

  void getUserData(String id) async{

    setState(() {
      _submit = true;
    });

    return _netUtil.get(NetworkUtil.getProfile, true).then((dynamic res) {

      setState(() {
        _submit = false;
      });

      if(this.parents_name == null || this.parents_name == ''){
        if(prefs.getString('parent_name') != null && prefs.getString('parent_name') != ''){
          this.parents_name = prefs.getString('parent_name')!;
        }
      }

      if (res != null && res["MessageType"] == 1) {

        if(res['profile'] != null){

        var user = json.encode(res['profile']);

        //print("Profile : " + user);

        Map<String, dynamic> jsonData = json.decode(user) as Map<String, dynamic>;

        //print("Profile : " + user);

        setState(() {
          profile_id = jsonData['id'];
          isSkipChild = (jsonData['is_adult'] == "0" ? false : true);
          nameController.text = (jsonData['name'] == null || jsonData['name'] == " " || jsonData['name'] == "" ? " " : jsonData['name']);
          parentnameController.text = (jsonData['parents_name'] == null || jsonData['parents_name'] == "" ? this.parents_name : jsonData['parents_name']);
          schoolController.text =  (jsonData['school'] == null || jsonData['school']== "" ? "" : jsonData['school']);
          classvalue = (jsonData['class'] == null || jsonData['class']== "" ? "Select Class" : jsonData['class']);
          classController.text = (jsonData['class'] == null || jsonData['class']== "" ? "" : jsonData['class']);
          dateController.text = (jsonData['date_of_birth'] == null || jsonData['date_of_birth'] == "" ? "" : jsonData['date_of_birth']);
          cityController.text = (jsonData['city'] == null || jsonData['city'] == "" ? "" : jsonData['city']);
          parentemailController.text = NetworkUtil.email;
          parentmobileController.text = (jsonData['parents_mobile'] == null || jsonData['parents_mobile'] == "" ? "" : jsonData['parents_mobile']);

          //if(isSkipChild){
          //  parentnameController.text = this.parents_name;
          //}
        });

      }


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

      }else{

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

    });
  }

  Future<bool> _onBack() async {

    if(isSkipChildChanged && isFromHome){
      setState(() {
        isSkipChild = !isSkipChild;
        isEdit = !isEdit;
        isSkipChildChanged = false;
        getUserData(userId!);
      });

      return false;

    }else if(!isFromHome){

      NetworkUtil.isLogin = false;
      NetworkUtil.isSocialLogin = false;
      NetworkUtil.isSubScribedUser = true;
      NetworkUtil.isAdult = false;
      NetworkUtil.subscription_end_date = '';

      prefs.setBool('isLogin', false);
      await secureStorage.deleteSecureData("password");
      prefs.clear();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => const WelcomeScreen(),
        ),
            (route) => false,
      );

      return true;

    }else{

      Navigator.pop(context);

      return true;
    }

  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBack,
      child : Scaffold(
      appBar : AppBar(
        automaticallyImplyLeading: true,
        leading: IconButton(
          onPressed: () async{
            if(isSkipChildChanged && isFromHome){
              setState(() {
                isSkipChild = !isSkipChild;
                isEdit = !isEdit;
                isSkipChildChanged = false;
                getUserData(userId!);
              });
            }else if(!isFromHome){

              NetworkUtil.isLogin = false;
              NetworkUtil.isSocialLogin = false;
              NetworkUtil.isSubScribedUser = true;
              NetworkUtil.isAdult = false;
              NetworkUtil.subscription_end_date = '';

              prefs.setBool('isLogin', false);
              await secureStorage.deleteSecureData("password");
              prefs.clear();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) => const WelcomeScreen(),
                ),
                    (route) => false,
              );

            }else{
              Navigator.pop(context);
            }

          },
          icon: Icon(Icons.arrow_back),
        ),
        backgroundColor: Color(0xffFCD800),
        title: Text('Profile',style: const TextStyle(color: Color(0xff000000),fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: Colors.black),
        actions: <Widget>[
          if(isFromHome)
          Padding(
              padding: EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    isEdit = !isEdit;
                  });
                },
                child: Icon(
                  Icons.edit,
                  size: 26.0,
                ),
              )
          ),
          Visibility(
            child: Padding(
                padding: EdgeInsets.only(right: 20.0),
                child: GestureDetector(
                  onTap: () {
                    showAlertDelete(context);
                  },
                  child: Icon(
                    Icons.delete_forever,
                    size: 26.0,
                  ),
                )
            ),
            visible: Platform.isIOS,
          ),
        ],
      ),
      body: ModalProgressHUD (child : Padding(
          padding: EdgeInsets.all(10),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            children: isEdit == true ? <Widget>[
              Container(
                width: 208,
                height: 228,
                alignment: Alignment.center,
                //padding: EdgeInsets.all(10),
                padding: EdgeInsets.fromLTRB(10, 10, 10, 5),
                child: Image(image: AssetImage('assets/earth_people.png')),
              ),
              if(!isFromHome) ...
              [
              Container(
                  alignment: Alignment.topLeft,
                  //padding: EdgeInsets.all(10),
                  padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                  child: Text(
                    'Build Your Profile',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  )),
                Container(
                    alignment: Alignment.topLeft,
                    padding: EdgeInsets.fromLTRB(10, 5, 10, 10),
                    child: Text(
                      'To serve you better please provide some information',
                      style: TextStyle(fontSize: 14),
                    )),
              ],
              //if(isEdit && !isFromHome)
                Container(
                  padding: EdgeInsets.all(10),
                  width: double.infinity,
                  //height: 50.0,
                  child : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        //alignment: Alignment.centerRight,
                        child: Text("Skip if you don't have a school going child"),
                      ),
                      Switch(
                        value: isSkipChild,
                        onChanged: (value) {
                          setState(() {
                            isSkipChild = value;
                            isSkipChildChanged = true;
                            nameController.text = "";
                            parentnameController.text = this.parents_name;//(isSkipChild ? this.parents_name : " ");
                            schoolController.text = "";
                            classvalue = "Select Class";
                            classController.text = "";
                            dateController.text = "";
                            cityController.text = "";
                            parentemailController.text = NetworkUtil.email;
                            parentmobileController.text = "";
                          });
                        },
                      ),
                    ],
                  ),
                  // child: OutlinedButton(
                  //   child: Text("Skip if you don't have a school going child"),
                  //   style: OutlinedButton.styleFrom(
                  //     primary: Colors.white,
                  //     backgroundColor: const Color(0xff579515),
                  //   ),
                  //   onPressed: () {
                  //
                  //     Navigator.pushAndRemoveUntil(
                  //         context,
                  //         MaterialPageRoute(
                  //             builder: (context) => WelcomeScreen()
                  //         ),
                  //         ModalRoute.withName("/")
                  //     );
                  //
                  //   },
                  // ),
                ),
              if(!isSkipChild)
              Container(
                padding: EdgeInsets.all(10),
                child: TextFormField(
                  autofocus: false,
                  controller: nameController,
                  decoration: InputDecoration(
                    isDense: true, // Added this
                    contentPadding: EdgeInsets.all(17),
                    border: OutlineInputBorder(
                      borderSide: const BorderSide(
                          color: Colors.lightGreenAccent, width: 0.0),
                    ),
                    labelText: "Your Child's Name",
                  ),
                    validator: RequiredValidator(errorText: "Required")
                ),
              ),
              // if(!isSkipChild)
              // Container(
              //   padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
              //   child: TextFormField(
              //     //autofocus: false,
              //     controller: parentnameController,
              //     decoration: InputDecoration(
              //       //isDense: true, // Added this
              //       contentPadding: EdgeInsets.all(17),
              //       border: OutlineInputBorder(
              //         borderSide: const BorderSide(
              //             color: Color(0xff6AA6A4), width: 0.0),
              //       ),
              //       labelText: 'Mother/Father/Guardian Name',
              //     ),
              //       validator: RequiredValidator(errorText: "Required")
              //   ),
              // ),
              if(!isSkipChild)
              Container(
                width: 50.0,
                padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: Column(
                    //mainAxisAlignment: MainAxisAlignment.center,
                    //crossAxisAlignment : CrossAxisAlignment.start,
                    children: [
                      //InputDecorator(
                      new DropdownButtonHideUnderline(
                      child : DropdownButtonFormField(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.0)),
                          contentPadding: EdgeInsets.fromLTRB(15, 5, 5, 5),
                        ),
                        hint: Text('Class'),
                        isExpanded: true,
                        //isDense: true,
                        value: classvalue,
                        icon: Icon(Icons.keyboard_arrow_down),
                        items:items.map((String items) {
                          return DropdownMenuItem(
                              value: items,
                              child: Text(items)
                          );
                        }
                        ).toList(),
                        onChanged: (String? newValue){
                          setState(() {
                            classvalue = newValue!;
                          },
                          );
                        },
                        validator: (value) => value == "Select Class" ? 'Required' : null,
                      ),
                      ),
                     // ),
                    ],
                  ),
              ),
              if(!isSkipChild)
              Container(
                padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: TextFormField(
                  autofocus: false,
                  controller: schoolController,
                  decoration: InputDecoration(
                    isDense: true, // Added this
                    contentPadding: EdgeInsets.all(17),
                    border: OutlineInputBorder(
                      borderSide: const BorderSide(
                          color: Color(0xff6AA6A4), width: 0.0),
                    ),
                    labelText: 'School',
                  ),
                   validator: RequiredValidator(errorText: "Required")
                ),
              ),
              if(!isSkipChild)
              Container(
                padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: GestureDetector(onTap: () =>
                  _selectDate(context),
                child: AbsorbPointer(
                child: TextFormField(
                  controller: dateController,
                  decoration: InputDecoration(
                    isDense: true, // Added this
                    contentPadding: EdgeInsets.all(17),
                    border: OutlineInputBorder(
                      borderSide: const BorderSide(
                          color: Color(0xff6AA6A4), width: 0.0),
                    ),
                    labelText: 'DOB',
                  ),
                  validator: RequiredValidator(errorText: "Required")
                ),
                ),
              ),
              ),
              //if(!isSkipChild)
              Container(
                padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: TextFormField(
                    autofocus: false,
                    controller: cityController,
                    decoration: InputDecoration(
                      isDense: true, // Added this
                      contentPadding: EdgeInsets.all(17),
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(
                            color: Color(0xff6AA6A4), width: 0.0),
                      ),
                      labelText: 'City',
                    ),
                    validator: RequiredValidator(errorText: "Required")
                ),
              ),
              //if(!isSkipChild)
              Container(
                padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: TextFormField(
                    autofocus: false,
                    controller: parentmobileController,
                    keyboardType: TextInputType.numberWithOptions(signed: true, decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      isDense: true, // Added this
                      contentPadding: EdgeInsets.all(17),
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(
                            color: Color(0xff6AA6A4), width: 0.0),
                      ),
                      labelText: (!isSkipChild ? "Mother/Father/Guardian's Mobile" : "Mobile No"),
                    ),
                    validator: RequiredValidator(errorText: "Required")
                ),
              ),
            ]
            : <Widget>[
              Container(
                width: 208,
                height: 228,
                alignment: Alignment.center,
                //padding: EdgeInsets.all(10),
                padding: EdgeInsets.fromLTRB(10, 10, 10, 5),
                child: Image(image: AssetImage('assets/earth_people.png')),
              ),
              if(!isFromHome) ... [
              Container(
                  alignment: Alignment.topLeft,
                  //padding: EdgeInsets.all(10),
                  padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                  child: Text(
                    'Build Your Profile',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  )),
              Container(
              alignment: Alignment.topLeft,
              padding: EdgeInsets.fromLTRB(10, 5, 10, 10),
              child: Text(
                'To serve you better please provide some information',
                style: TextStyle(fontSize: 14),
              )),
              ],
              if(!isSkipChild)
              Container(
                child: TextFormField(
                    autofocus: false,
                    readOnly: true,
                    controller: nameController,
                    decoration: InputDecoration(
                      isDense: true, // Added this
                      contentPadding: EdgeInsets.all(17),
                      labelText: "Your Child's Name",
                    ),
                    validator: RequiredValidator(errorText: "Required")
                ),
              ),
              // if(!isSkipChild)
              // Container(
              //   //padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
              //   child: TextFormField(
              //       autofocus: false,
              //       readOnly: true,
              //       controller: parentnameController,
              //       decoration: InputDecoration(
              //         isDense: true, // Added this
              //         contentPadding: EdgeInsets.all(17),
              //         labelText: 'Mother/Father/Guardian Name',
              //       ),
              //       validator: RequiredValidator(errorText: "Required")
              //   ),
              // ),
              if(!isSkipChild)
              Container(
                //padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: TextFormField(
                    autofocus: false,
                    readOnly: true,
                    controller: classController,
                    decoration: InputDecoration(
                      isDense: true, // Added this
                      contentPadding: EdgeInsets.all(17),
                      labelText: 'Class',
                    ),
                    validator: RequiredValidator(errorText: "Required")
                ),
              ),
              if(!isSkipChild)
              Container(
                //padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: TextFormField(
                    autofocus: false,
                    readOnly: true,
                    controller: schoolController,
                    decoration: InputDecoration(
                      isDense: true, // Added this
                      contentPadding: EdgeInsets.all(17),
                      labelText: 'School',
                    ),
                    validator: RequiredValidator(errorText: "Required")
                ),
              ),
              if(!isSkipChild)
              Container(
                //padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: AbsorbPointer(
                    child: TextFormField(
                        controller: dateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          isDense: true, // Added this
                          contentPadding: EdgeInsets.all(17),
                          labelText: 'DOB',
                        ),
                        validator: RequiredValidator(errorText: "Required")
                    ),
                ),
              ),
              Container(
                //padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: TextFormField(
                    autofocus: false,
                    readOnly: true,
                    controller: cityController,
                    decoration: InputDecoration(
                      isDense: true, // Added this
                      contentPadding: EdgeInsets.all(17),
                      labelText: 'City',
                    ),
                    validator: RequiredValidator(errorText: "Required")
                ),
              ),
              // Container(
              //   //padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
              //   child: TextFormField(
              //     autofocus: false,
              //     readOnly: true,
              //     controller: parentemailController,
              //     decoration: InputDecoration(
              //       isDense: true, // Added this
              //       contentPadding: EdgeInsets.all(17),
              //       labelText: "Mother/Father/Guardian's Email",
              //     ),
              //     validator: MultiValidator([
              //       RequiredValidator(errorText: "Required"),
              //       EmailValidator(errorText: "Please enter a valid email address"),
              //     ]),
              //   ),
              // ),
              Container(
                //padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: TextFormField(
                    autofocus: false,
                    readOnly: true,
                    controller: parentmobileController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      isDense: true, // Added this
                      contentPadding: EdgeInsets.all(17),
                      labelText: (!isSkipChild ? "Mother/Father/Guardian's Mobile" : "Mobile No"),
                    ),
                    validator: RequiredValidator(errorText: "Required")
                ),
              ),
            ],
          ),
        ),
      ),inAsyncCall: _submit
    ),
      persistentFooterButtons: [
        if(isEdit)
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              width: double.infinity,
              height: 50.0,
              child: OutlinedButton(
                child: Text(isEdit && !isFromHome ? 'Create an Account' : 'Update Profile'),
                style: OutlinedButton.styleFrom(
                  primary: Colors.white,
                  backgroundColor: const Color(0xff579515),
                ),
                onPressed: () {
                  _netUtil.isConnected().then((internet) {
                    if (internet) {
                      if (_formKey.currentState!.validate()) {
                        setState(() {
                          _submit = true;
                        });

                        UserProfile();
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
    )
    );
  }

  _selectDate(BuildContext context) async {
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (selected != null && selected != selectedDate)
      setState(() {
        FocusScope.of(context).requestFocus(new FocusNode());
        selectedDate = selected;
        var date =
            "${selected.toLocal().year}-${selected.toLocal().month}-${selected.toLocal().day}";
        dateController.text = date;
      });
  }

  void UserProfile() {


    var body = {

      "profile_id" : profile_id.toString(),
      "is_adult" : (isSkipChild ? "1" : "0"),
      "child_name" : (isSkipChild ? "" : nameController.text),
      "name": (isSkipChild ? "" : nameController.text),
      "parents_name" : this.parents_name,//(isSkipChild ? parentnameController.text : parentnameController.text),
      "class" : (isSkipChild ? "" : classvalue),
      "school": (isSkipChild ? "" : schoolController.text),
      "date_of_birth" : (isSkipChild ? dateController.text : dateController.text),
      "city" : (isSkipChild ? cityController.text : cityController.text),
      "parents_email" : NetworkUtil.email,
      "parents_mobile" : (isSkipChild ? parentmobileController.text : parentmobileController.text)

    };


    //print("profile data : " + body.toString());

     _netUtil.post(NetworkUtil.createUserProfile,body,true).then((dynamic res) {

      //print("createUserProfile : " + res.toString());

      setState(() {
        _submit = false;
      });

      if(res != null && res["MessageType"] == 1){

        Fluttertoast.showToast(
            msg: res["Message"],
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.SNACKBAR,
            timeInSecForIosWeb: 1,
            backgroundColor: Color(0xff69F0AE),
            textColor: Color(0xff19442C),
            fontSize: 16.0
        );

        //prefs.setBool('isAdult', isSkipChild);
        //NetworkUtil.isAdult = isSkipChild;

        if(isEdit && !isFromHome){

          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => Dashboard()
              ),
              ModalRoute.withName("/")
          );

        }else{

          setState(() {
            isSkipChildChanged = false;
          });
          getUserData(userId!);

        }

      }else if(res != null && res["MessageType"] == 0){

        Fluttertoast.showToast(
            msg: res["Message"],
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.SNACKBAR,
            timeInSecForIosWeb: 1,
            backgroundColor: Color(0xff69F0AE),
            textColor: Color(0xff19442C),
            fontSize: 16.0
        );


      }else{

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

  showAlertDelete(BuildContext context) {
    Widget continueButton = TextButton(
      child: Text("YES"),
      onPressed: () {
        deleteAccount();
      },
    );

    Widget cancelButton = TextButton(
      child: Text("NO"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Warning"),
      content: Text("Your account will be deleted permanently. Are you sure you want to delete your account?"),
      actions: [
        continueButton,
        cancelButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void deleteAccount() async
  {
    return _netUtil.get(NetworkUtil.deleteUserAccount, true).then((dynamic res)
    async {

      print("DeleteAcc = "+res.toString());

      if (res != null && res["MessageType"] == 1)
      {
        Fluttertoast.showToast(
            msg: "Account deleted.",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.SNACKBAR,
            timeInSecForIosWeb: 1,
            backgroundColor: Color(0xff69F0AE),
            textColor: Color(0xff19442C),
            fontSize: 16.0);

        NetworkUtil.isLogin = false;
        NetworkUtil.isSocialLogin = false;
        NetworkUtil.isSubScribedUser = true;
        NetworkUtil.isAdult = false;
        NetworkUtil.subscription_end_date = '';
        NetworkUtil.UserName = '';
        NetworkUtil.email = '';

        prefs.setBool('isLogin', false);
        await secureStorage.deleteSecureData("password");
        prefs.clear();

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => const Dashboard(),
          ),
              (route) => false,
        );
      }
      else{
        Fluttertoast.showToast(
            msg: 'Something went wrong.',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.SNACKBAR,
            timeInSecForIosWeb: 1,
            backgroundColor: Color(0xffE74C3C),
            textColor: Colors.white,
            fontSize: 16.0);
      }

    });
  }

  void login(String username, String password) {

    var body = {
      "email": username,
      "password": password,
      "deviceId": NetworkUtil.deviceId,
      "Appversion": NetworkUtil.AppVersion
    };

    //print("login body " + body.toString());
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

        prefs.setBool('isAdult', isSkipChild);
        NetworkUtil.isAdult = isSkipChild;

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
}