import 'dart:convert';

import 'package:CFE/Networking/networkUtil.dart';
import 'package:CFE/models/PlanList.dart';
import 'package:CFE/screen/IosPayment.dart';
import 'package:CFE/screen/WebViewScreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'PaymentHistory.dart';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';
//import 'package:sn_progress_dialog/progress_dialog.dart';


class PaymentSelection extends StatefulWidget {
  const PaymentSelection({Key? key}) : super(key: key);

  @override
  PaymentSelectionState createState() => PaymentSelectionState();
}

class PlansList {

  int? id;
  String? title;
  String? subtitle;
  String? price;

  PlansList(this.id,
    this.title,this.subtitle,this.price);
}

class PaymentSelectionState extends State<PaymentSelection> {

  NetworkUtil _netUtil = new NetworkUtil();
  List<PlanList> pList = <PlanList>[];

  List<PlansList> subPlanList = <PlansList>[];
  late PlansList selectedPlan;
  int selectPlanIndex = 0;
  bool _submit = false;
  late var endDate;
  var subPlan = '';
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();

    getPreferenceData();

    if(NetworkUtil.isSubScribedUser){

      var inputFormat = DateFormat('yyyy-MM-dd');
      var inputDate = inputFormat.parse(NetworkUtil.subscription_end_date); // <-- dd/MM 24H format

      var outputFormat = DateFormat('dd MMM yyyy');
      endDate = outputFormat.format(inputDate);

    }else{
      endDate = '';
    }

    //getPlandetails();

  }

  getPreferenceData() async {
    prefs = await SharedPreferences.getInstance();

    await _netUtil.isConnected().then((internet) {
      if (internet) {
        getUserData();
      } else {
        NetworkUtil.showDialogNoInternet(
            'You are disconnected to the Internet.',
            'Please check your internet connection',
            context);
      }
    });
  }

  getPlandetails(){

    setState(() {
      _submit = true;
    });

    return _netUtil.get(NetworkUtil.getPlans, true).then((dynamic res) {

      //var plans = json.encode(res['plans']);

      setState(() {
        _submit = false;
      });
      NetworkUtil.StripePublishablekey = res['stripe_key'];

      if (res != null && res["MessageType"] == 1) {

        for (var v in res['plans']) {
          pList.add(PlanList.fromJson(v));
        }

        for (var i = 0; i < pList.length; i++) {
          PlansList q = new PlansList(pList[i].id, pList[i].title,pList[i].identifier,pList[i].price);
          subPlanList.add(q);
        }

        setState(() {
          selectedPlan = subPlanList[0];
        });

        //StripeService.init();
        //print("subplanList" + subPlanList[0].title.toString());
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

  getSubscriptionEndDate(String plan,String msg){

    print("plan" + plan);
    setState(() {
      _submit = true;
    });

    NetworkUtil.subscriptionSuccess = "api/subscription/" + plan + "/status";
    return _netUtil.get(NetworkUtil.subscriptionSuccess, true).then((dynamic res) {

      setState(() {
        _submit = false;
      });

      if (res != null && res["MessageType"] == 1) {

        setState(() {

          NetworkUtil.isSubScribedUser = true;
          NetworkUtil.subscription_end_date = res["subscription_end_date"];

          var inputFormat = DateFormat('yyyy-MM-dd');
          var inputDate = inputFormat.parse(NetworkUtil.subscription_end_date); // <-- dd/MM 24H format

          var outputFormat = DateFormat('dd MMM yyyy');
          endDate = outputFormat.format(inputDate);

      });

        Fluttertoast.showToast(
            msg: msg,
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.SNACKBAR,
            timeInSecForIosWeb: 1,
            backgroundColor: Color(0xffDA4542),
            textColor: Colors.white,
            fontSize: 16.0
        ).then((value) => Navigator.pop(context));

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

  @override
  Widget build(BuildContext context) {
    //ThemeData theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Color(0xffF9F9F9),
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.black),
        backgroundColor: Color(0xffFCD800),
        title: Text('Subscription',style: TextStyle(color : Color(0xff000000),fontWeight: FontWeight.bold)),
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
      body: ModalProgressHUD ( child :
      ListView(
        //mainAxisAlignment: MainAxisAlignment.start,
          children: !NetworkUtil.isSubScribedUser ? <Widget>[
            Container(
              width: 208,
              height: 228,
              alignment: Alignment.center,
              //padding: EdgeInsets.all(10),
              padding: EdgeInsets.fromLTRB(10, 10, 10, 5),
              child: Image(image: AssetImage('assets/kid-money.png')),
            ),
            Container(
                alignment: Alignment.topLeft,
                //padding: EdgeInsets.all(10),
                padding: EdgeInsets.fromLTRB(25, 15, 10, 5),
                child: Text(
                  'Click on make payment to start your subscription.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                )
            ),
        ] : <Widget> [
            Container(
              width: 208,
              height: 228,
              alignment: Alignment.center,
              //padding: EdgeInsets.all(10),
              padding: EdgeInsets.fromLTRB(10, 10, 10, 5),
              child: Image(image: AssetImage('assets/kid-money.png')),
            ),
            Container(
                alignment: Alignment.topLeft,
                //padding: EdgeInsets.all(10),
                //padding: EdgeInsets.fromLTRB(20, 5, 20, 5),
                margin: const EdgeInsets.only(left: 30.0, right: 20.0,bottom: 5.0,top: 20.0),
                child: Text(
                        'Thank you for subscribing to the Children For Environment App.',
                        style: TextStyle(fontSize: 14),
                      ),
                ),
            Container(
              alignment: Alignment.topLeft,
              //padding: EdgeInsets.all(10),
              //padding: EdgeInsets.fromLTRB(20, 5, 20, 5),
              margin: const EdgeInsets.only(left: 30.0, right: 20.0,bottom: 5.0),
              child: Text(
                'You have subscribed to the ' + subPlan + ' plan with full access.',
                style: TextStyle(fontSize: 14),
              ),
            ),
            Container(
                alignment: Alignment.topLeft,
                margin: const EdgeInsets.only(left: 30.0, right: 20.0),
                //padding: EdgeInsets.fromLTRB(20, 5, 20, 5),
                child: Text(
                        'Your subscription ends on: ' + endDate + '.',
                        style: TextStyle(fontSize: 14),
                      ),
              ),
          ],
      ),
          inAsyncCall: _submit
      ),
      persistentFooterButtons: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.end,
          children: !NetworkUtil.isSubScribedUser ? <Widget>[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              width: double.infinity,
              height: 50.0,
              child: OutlinedButton(
                child: Text('Make Payment'),
                style: OutlinedButton.styleFrom(
                  primary: Colors.white,
                  backgroundColor: const Color(0xff579515),
                ),
                onPressed: (!NetworkUtil.isSubScribedUser) ? () =>  {
                  redirectToPayment()
                } : null,
              ),
            ),
          ] : <Widget>[],
        ),
      ],
    );
  }

  List<Widget> createRadioListUsers() {
    List<Widget> widgets = [];
    for (var i=0; i< subPlanList.length; i++) {
      widgets.add(
        RadioListTile(
          value: subPlanList[i],
          groupValue: selectedPlan,
          title: Text(subPlanList[i].title.toString()),// + '  ' + subPlanList[i].price.toString() + ''),
          //subtitle: Text(subPlanList[i].subtitle.toString()),
          onChanged: (current) {
            //print("Current User ${current!}");
            //setSelectedUser(current);
            setState(() {
              selectedPlan = current as PlansList;
              selectPlanIndex = i;
            });

            print("Current User " + selectedPlan.id.toString() + i.toString());

          },
          selected: selectedPlan == subPlanList[i],
          activeColor: Colors.green,
        ),
      );
    }
    return widgets;
  }

  void subscriptionSuccess(int status, String setupIntentId) {

    //print("subscriptionSuccess body : " + body.toString());

    NetworkUtil.subscriptionSuccess = "api/subscription/premium/status";
    _netUtil.get(NetworkUtil.subscriptionSuccess,true).then((dynamic res) {

      //print("status : " + res.toString());

      if(res != null && res["MessageType"] == 1){

        Fluttertoast.showToast(
            msg: res["Message"],
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.SNACKBAR,
            timeInSecForIosWeb: 1,
            backgroundColor: Color(0xffDA4542),
            textColor: Colors.white,
            fontSize: 16.0
        );

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

  void redirectToPayment() async
  {
    try
    {
      if (Platform.isAndroid) {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (BuildContext context) => WebViewEx(),
          ),
        ).then((value) => {

          if (mounted) {
            getUserData()
          }
        });
      } else if (Platform.isIOS) {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (BuildContext context) => IosPayment(),
          ),
        ).then((value) => {

          if (mounted) {
            getUserData()
          }
        });
      }
    } on PlatformException {
      print('Failed to get platform version');
    }
  }

  void getUserData() async
  {
    try
    {
      setState(() {
        _submit = true;
      });

      return _netUtil.get(NetworkUtil.getUserDetail, true).then((dynamic res) {

        var user = json.encode(res['user']);

        Map<String, dynamic> jsonData = json.decode(user) as Map<String, dynamic>;

        print("user : " + res.toString());

        //playStoreVersion = double.parse(res['Appversion'].toString());

        if (res != null && res["MessageType"] == 1)
        {
          prefs.setString("UserId", jsonData['id'].toString());

          if (jsonData['email'] != null) {
            prefs.setString('email', jsonData['email']);
          }


          setState(() {
            _submit = false;
            if (res["subscription_end_date"] != null) {
              NetworkUtil.subscription_end_date = res["subscription_end_date"];
            }

            if(NetworkUtil.subscription_end_date != null && NetworkUtil.subscription_end_date.length > 0){

              var inputFormat = DateFormat('yyyy-MM-dd');
              var inputDate = inputFormat.parse(NetworkUtil.subscription_end_date); // <-- dd/MM 24H format

              var outputFormat = DateFormat('dd MMM yyyy');
              endDate = outputFormat.format(inputDate);

            }else{
              endDate = '';
            }

            try
            {
              if (Platform.isAndroid)
              {
                if(res["razor_plan"] != null)
                {
                  subPlan = res["razor_plan"];
                  subPlan = subPlan.replaceAll(RegExp('_'), ' ');
                }
                else{
                  subPlan = '';
                }
              }
              else if (Platform.isIOS)
              {
                if(res["app_store_plan"] != null)
                {
                  if (res["app_store_plan"] == "Half_Yearly_Plan_CFE") {
                    subPlan = "Half Yearly";
                  }
                  else if (res["app_store_plan"] == "Yearly_Plan_CFE"){
                    subPlan = "Yearly";
                  }
                  else {
                    subPlan = res["app_store_plan"];
                  }
                }
                else{
                  subPlan = '';
                }
              }
            } on PlatformException {
              print('Failed to get platform version');
            }

            if (res["subscribed"] == 0) {
              NetworkUtil.isSubScribedUser = false;
            } else {
              NetworkUtil.isSubScribedUser = true;
            }

            if (jsonData['name'] != null) {
              NetworkUtil.UserName = jsonData['name'];
            }

            if (jsonData['email'] != null) {
              NetworkUtil.email = jsonData['email'];
            }
          });

          //print("user NetworkUtil: " + NetworkUtil.UserName + NetworkUtil.email);
        }else{

          setState(() {
            _submit = false;
          });

        }

      });
    }
    catch(err) {print(err.toString());}
  }

}