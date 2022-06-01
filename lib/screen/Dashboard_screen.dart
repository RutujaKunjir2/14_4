import 'dart:async';
import 'dart:convert';
import 'package:CFE/Networking/networkUtil.dart';
import 'package:CFE/models/ExpansionpanelItem.dart';
import 'package:CFE/models/categoriesListModel.dart';
import 'package:CFE/models/categoriesModel.dart';
import 'package:CFE/models/detailListModel.dart';
import 'package:CFE/screen/BuildProfile_screen.dart';
import 'package:CFE/screen/Faqs_screen.dart';
import 'package:CFE/screen/FastFacts_screen.dart';
import 'package:CFE/screen/FavoritesList_screen.dart';
import 'package:CFE/screen/Feed_screen.dart';
import 'package:CFE/screen/IosPayment.dart';
import 'package:CFE/screen/PaymentHistory.dart';
import 'package:CFE/screen/PaymentSelection.dart';
import 'package:CFE/screen/WebViewScreen.dart';
import 'package:CFE/services/storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:store_redirect/store_redirect.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../icons.dart';
import 'Disclaimer_screen.dart';
import 'Login_screen.dart';
import 'Welcome_screen.dart';
import 'categoryContent.dart';
import 'dart:io' show Platform;

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  State<Dashboard> createState() => _DashboardWidgetState();
}

/// This is the private State class that goes with MyStatefulWidget.
class _DashboardWidgetState extends State<Dashboard>
    with WidgetsBindingObserver {
  Map<String, String> headers = {
    "Authorization": "Bearer " + NetworkUtil.token
  };

  Timer? periodicTimer;
  Future<detailListModel>? detailItems;
  bool isSearchCalled = false;
  bool isSearchLoader = false;
  String previousSearchText = '';
  int openLastindex = -1;
  List<ExpansionpanelItem>? detailItemsListView = <ExpansionpanelItem>[];
  ScrollController _sc = new ScrollController();
  final _height = 60.0;
  final scrollDirection = Axis.vertical;
  bool isLoadingLazy = false;
  bool _hasMore = true;
  int page = 0;
  int pageCount = 10;
  final itemKey = GlobalKey();

  late SharedPreferences prefs;
  DateTime pre_backpress = DateTime.now();
  int _selectedIndex = 0;
  NetworkUtil _netUtil = new NetworkUtil();
  Future<categoriesListModel>? categotiesListFuture;
  GlobalKey<ScaffoldState> _key = new GlobalKey<ScaffoldState>();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();
  List<categoriesModel>? categoryListView = <categoriesModel>[];
  List<categoriesModel>? filtercatListView = <categoriesModel>[];
  late SecureStorage secureStorage;
  String playStoreVersion = "1.0.0";
  String appStoreVersion = "1.0.0";
  late FocusNode focusNode;
  final TextEditingController _filtercat = new TextEditingController();
  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  static const List<Widget> _widgetOptions = <Widget>[
    Text(
      'Index 0: Home',
      style: optionStyle,
    ),
    Text(
      'Index 1: Feed',
      style: optionStyle,
    ),
    Text(
      'Index 2: Gallery',
      style: optionStyle,
    ),
    Text(
      'Index 3: Favorites',
      style: optionStyle,
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _filtercat.text = '';
      isSearchCalled = false;
      focusNode.unfocus();
    });

    //print("selected index : " + _selectedIndex.toString());

    if (_selectedIndex == 3)
    {
      if(NetworkUtil.isLogin)
      {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (BuildContext context) => BuildProfile(
                isEdit: false,
                isFromHome: true,
                parents_name: NetworkUtil.UserName),
          ),
        ).then((value) => setState(() => {_selectedIndex = 0, getUserData()}));
      }
      else
      {
        showAlertLogin(context);
      }
    }
    else if (_selectedIndex == 2)
    {
      if(NetworkUtil.isLogin)
      {
        if (NetworkUtil.isSubScribedUser) {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (BuildContext context) => FavoritesList(),
            ),
          ).then((value) => setState(() => {_selectedIndex = 0}));
        } else {
          Fluttertoast.showToast(
              msg: NetworkUtil.subscription_end_date == ''
                  ? 'Start your subscription'
                  : 'Renew Your Membership',
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.SNACKBAR,
              timeInSecForIosWeb: 1,
              backgroundColor: Color(0xffE74C3C),
              textColor: Colors.white,
              fontSize: 16.0);
        }
      }
      else
      {
        showAlertLogin(context);
      }

    } else if (_selectedIndex == 1)
    {
      if(NetworkUtil.isLogin)
      {
        if (NetworkUtil.isSubScribedUser) {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (BuildContext context) => FeedScreen(),
            ),
          ).then((value) => setState(() => {_selectedIndex = 0}));
        } else {
          Fluttertoast.showToast(
              msg: NetworkUtil.subscription_end_date == ''
                  ? 'Start your subscription'
                  : 'Renew Your Membership',
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.SNACKBAR,
              timeInSecForIosWeb: 1,
              backgroundColor: Color(0xffE74C3C),
              textColor: Colors.white,
              fontSize: 16.0);
        }
      }
      else
      {
        showAlertLogin(context);
      }
    } else if (_selectedIndex == 0) {}
  }

  @override
  void initState() {
    print("init state called");
    _sc = ScrollController();
    super.initState();

    getPreferenceData();

    focusNode = FocusNode();

    _filtercat.addListener(() {
      if (_filtercat.text.isEmpty) {
        setState(() {
          isSearchCalled = false;
          _filtercat.clear();
          categoryListView = filtercatListView;
        });
      } else {
        if (previousSearchText != _filtercat.text) {
          previousSearchText = _filtercat.text;

          setState(() {
            if (periodicTimer != null) {
              periodicTimer!.cancel();
            }
            isSearchCalled = true;
            isSearchLoader = true;
            page = 0;
            detailItemsListView = <ExpansionpanelItem>[];

            periodicTimer = Timer.periodic(
              const Duration(seconds: 2),
              (timer) {
                //print("api called");
                detailItems = getAppSearchList(0);
                isSearchLoader = false;
                periodicTimer!.cancel();
              },
            );
          });
        }
      }
    });

    _sc.addListener(() {
      //print("lazy listener");
      if (_sc.position.pixels == _sc.position.maxScrollExtent) {
        //print("lazy load listener called" + _hasMore.toString());

        if (_hasMore) {
          //print("lazy load called");
          Future<detailListModel> data = getAppSearchList(page);
        }
      }
    });
  }

  getPreferenceData() async {
    prefs = await SharedPreferences.getInstance();

    secureStorage = await SecureStorage();

    bool? isLogin = await prefs.getBool('isLogin');

    await _netUtil.isConnected().then((internet) {
      if (internet) {
        if(isLogin != null){
          if(isLogin) {
            getUserData();
          }
          else{
            setState(() {
              // calling API to show the data
              // you can also do it with any button click.
              categoryListView = [];
              categotiesListFuture = getcategoriesList();
            });
          }
        }
        else{
          setState(() {
            // calling API to show the data
            // you can also do it with any button click.
            categoryListView = [];
            categotiesListFuture = getcategoriesList();
          });
        }
      } else {
        NetworkUtil.showDialogNoInternet(
            'You are disconnected to the Internet.',
            'Please check your internet connection',
            context);
      }
    });
  }

  Future<categoriesListModel> getcategoriesList() async {
    return _netUtil.get(NetworkUtil.getCategories, true).then((dynamic res) {
      //json.decode used to decode response.body(string to map)
      //print(res.toString());

      if (res != null && res["MessageType"] == 1) {
        //NetworkUtil.isSubScribedUser = true;

        getcatList(res['categories']);
        return categoriesListModel.fromJson(res['categories']);
      } else if (res != null && res["MessageType"] == 0) {
        Fluttertoast.showToast(
            msg: res["Message"],
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.SNACKBAR,
            timeInSecForIosWeb: 1,
            backgroundColor: Color(0xffE74C3C),
            textColor: Colors.white,
            fontSize: 16.0);

        return categoriesListModel.fromJson([]);
      } else if (res != null && res["MessageType"] == -1) {
        //NetworkUtil.isSubScribedUser = false;

        Fluttertoast.showToast(
            msg: res["Message"],
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.SNACKBAR,
            timeInSecForIosWeb: 1,
            backgroundColor: Color(0xffE74C3C),
            textColor: Colors.white,
            fontSize: 16.0);

        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (BuildContext context) => const PaymentSelection(),
          ),
        );

        return categoriesListModel.fromJson([]);
      } else {
        Fluttertoast.showToast(
            msg: 'Something went wrong.',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.SNACKBAR,
            timeInSecForIosWeb: 1,
            backgroundColor: Color(0xffE74C3C),
            textColor: Colors.white,
            fontSize: 16.0);

        return categoriesListModel.fromJson([]);
      }
    });
  }

  void getcatList(List<dynamic> parsedJson) {
    for (var v in parsedJson) {
      categoryListView!.add(categoriesModel.fromJson(v));
    }

    setState(() {
      filtercatListView = categoryListView;
    });

    //return detailList;
  }

  void getUserData() async {
    return _netUtil.get(NetworkUtil.getUserDetail, true).then((dynamic res) {
      var user = json.encode(res['user']);

      Map<String, dynamic> jsonData = json.decode(user) as Map<String, dynamic>;

      //print("user : " + user);

      playStoreVersion = res['AppversionAndroid'].toString();
      appStoreVersion = res['AppversionIos'].toString();

      print("user : " + res.toString());
      print("userToken : " + NetworkUtil.token);

      if (res != null && res["MessageType"] == 1) {
        if (jsonData['profile'] != null) {
          prefs.setString("UserId", jsonData['id'].toString());
          prefs.setString('email', jsonData['email']);

          setState(() {
            if (res["subscription_end_date"] != null) {
              NetworkUtil.subscription_end_date = res["subscription_end_date"];
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
        } else {
          Fluttertoast.showToast(
              msg: "Please update profile first.",
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.SNACKBAR,
              timeInSecForIosWeb: 1,
              backgroundColor: Color(0xff69F0AE),
              textColor: Color(0xff19442C),
              fontSize: 16.0);

          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (BuildContext context) => BuildProfile(
                  isEdit: false,
                  isFromHome: true,
                  parents_name: NetworkUtil.UserName),
            ),
          ).then((value) => {
                if (this.mounted)
                  {
                    setState(() {
                      getUserData();
                    })
                  }
              });
        }

        //print("user NetworkUtil: " + NetworkUtil.UserName + NetworkUtil.email);
      }

      if (Platform.isAndroid) {
        int InstallAppVersion =
            getExtendedVersionNumber(NetworkUtil.AppVersion); // return 102003
        int playversion = getExtendedVersionNumber(
            playStoreVersion.toString()); // return 102011
        if (InstallAppVersion < playversion) {
          //print("update dialog ");
          showAlertDialog(context);
        } else {
          setState(() {
            // calling API to show the data
            // you can also do it with any button click.
            categoryListView = [];
            categotiesListFuture = getcategoriesList();
          });
        }
      } else if (Platform.isIOS) {
        int InstallAppVersion =
            getExtendedVersionNumber(NetworkUtil.AppVersion); // return 102003
        int playversion = getExtendedVersionNumber(appStoreVersion.toString());
        if (InstallAppVersion < playversion) {
          //print("update dialog ");
          showAlertDialog(context);
        } else {
          setState(() {
            // calling API to show the data
            // you can also do it with any button click.
            categoryListView = [];
            categotiesListFuture = getcategoriesList();
          });
        }
      } else {
        //getUserData();

        //print("isSubScribedUser " + NetworkUtil.isSubScribedUser.toString());

        //if(NetworkUtil.isSubScribedUser){
        // set state while we fetch data from API
        setState(() {
          // calling API to show the data
          // you can also do it with any button click.
          categoryListView = [];
          categotiesListFuture = getcategoriesList();
        });
        //}

      }
    });
  }

  int getExtendedVersionNumber(String version) {
    // Note that if you want to support bigger version cells than 99,
    // just increase the returned versionCells multipliers
    List versionCells = version.split('.');
    versionCells = versionCells.map((i) => int.parse(i)).toList();
    return versionCells[0] * 10000 + versionCells[1] * 100 + versionCells[2];
  }

  @override
  didChangeDependencies() {
    //print("is mounted " + this.mounted.toString());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    //print('AppLifecycleState: $state');
  }

  @override
  void deactivate() {
    // TODO: implement deactivate
    //print("deactivate");
    super.deactivate();
  }

  @override
  didUpdateWidget(Dashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    //print("is mounted didUpdateWidget : " + this.mounted.toString());
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        //print("isDrawerOpen io:" + _key.currentState!.isDrawerOpen.toString());
        if (_key.currentState!.isDrawerOpen) {
          //print("isDrawerOpen :" + _key.currentState!.isDrawerOpen.toString());
          setState(() {
            _filtercat.text = '';
            isSearchCalled = false;
          });

          Navigator.of(context).pop();
          return false;
        } else {
          //print("isDrawerOpen : close");
          final timegap = DateTime.now().difference(pre_backpress);
          final cantExit = timegap >= Duration(seconds: 2);
          pre_backpress = DateTime.now();
          if (cantExit) {
            //show snackbar
            final snack = SnackBar(
              content: Text('Press Back button again to Exit'),
              duration: Duration(seconds: 2),
            );
            ScaffoldMessenger.of(context).showSnackBar(snack);
            return false;
          } else {
            return true;
          }
        }
      },
      child: Scaffold(
        key: _key,
        backgroundColor: Color(0xffF9F9F9),
        appBar: AppBar(
          backgroundColor: Color(0xffFCD800),
          title: const Text('Categories',
              style: TextStyle(
                  color: Color(0xff000000), fontWeight: FontWeight.bold)),
          iconTheme: IconThemeData(color: Colors.black),
          actions: <Widget>[
            Padding(
                padding: EdgeInsets.only(right: 20.0),
                child: GestureDetector(
                  onTap: () {
                    shareApp(context);
                  },
                  child: Icon(
                    Icons.share,
                    size: 26.0,
                  ),
                )),
          ],
        ),
        drawer:
            // Container(width: MediaQuery.of(context).size.width * 0.75,
            //   child :
            Drawer(
          elevation: 10.0,
          //child: Column(
          child: ListView(
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(color: Color(0xffFCD800)
                    // image: DecorationImage(
                    //     image: AssetImage("assets/earth_people.png"),
                    //     fit: BoxFit.cover
                    // )
                    ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // CircleAvatar(
                    //   backgroundImage: NetworkImage('https://pixel.nymag.com/imgs/daily/vulture/2017/06/14/14-tom-cruise.w700.h700.jpg'),
                    //   radius: 40.0,
                    // ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "Welcome,",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontSize: 25.0,
                            ),
                          ),
                          SizedBox(height: 5.0),
                          Text(
                            NetworkUtil.UserName,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontSize: 17.0,
                            ),
                          ),
                          SizedBox(height: 10.0),
                          Text(
                            NetworkUtil.email,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                fontSize: 14.0),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              //Here you place your menu items
              ListTile(
                leading: Icon(Icons.home),
                title: Text('Home', style: TextStyle(fontSize: 18)),
                onTap: () {
                  // Here you can give your route to navigate
                  Navigator.of(context).pop();
                },
              ),
              Divider(height: 3.0),
              Visibility(
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Profile Setting', style: TextStyle(fontSize: 18)),
                  onTap: () {
                    Navigator.of(context).pop();
                    // Here you can give your route to navigate
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (BuildContext context) => BuildProfile(
                            isEdit: false,
                            isFromHome: true,
                            parents_name: NetworkUtil.UserName),
                      ),
                    ).then((value) => {
                      if (this.mounted)
                        {
                          setState(() {
                            getUserData();
                          })
                        }
                    });
                  },
                ),
                visible: NetworkUtil.isLogin,
              ),
              Divider(height: 3.0),
              ListTile(
                leading: Icon(Icons.credit_card),
                title: Text('Payment', style: TextStyle(fontSize: 18)),
                onTap: () {
                  Navigator.of(context).pop();

                  if(NetworkUtil.isLogin)
                  {
                    if (NetworkUtil.isSubScribedUser) {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (BuildContext context) => PaymentSelection(),
                        ),
                      );
                    } else {
                      try
                      {
                        if (Platform.isAndroid) {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (BuildContext context) => WebViewEx(),
                            ),
                          );
                        } else if (Platform.isIOS) {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (BuildContext context) => IosPayment(),
                            ),
                          );
                        }
                      } on PlatformException {
                        print('Failed to get platform version');
                      }

                    }
                  }
                  else
                  {
                    showAlertLogin(context);
                  }
                },
              ),
              Divider(height: 3.0),
              ListTile(
                leading: Icon(Customicons.faqs),
                title: Text('FAQs', style: TextStyle(fontSize: 18)),
                onTap: () {
                  Navigator.of(context).pop();
                  // Here you can give your route to navigate
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (BuildContext context) => FaqsScreen(),
                    ),
                  );
                },
              ),
              Divider(height: 3.0),
              ListTile(
                leading: Icon(Icons.privacy_tip_outlined),
                title: Text('Privacy Policy', style: TextStyle(fontSize: 18)),
                onTap: () async {
                  Navigator.of(context).pop();

                  if (await canLaunch(
                      "https://childrenforenvironment.com/privacy_policy")) {
                    await launch(
                        "https://childrenforenvironment.com/privacy_policy");
                  } else {
                    throw 'Could not launch ';
                  }
                },
              ),
              Divider(height: 3.0),
              ListTile(
                leading: Icon(Icons.account_balance_wallet_outlined),
                title:
                    Text('Terms & Conditions', style: TextStyle(fontSize: 18)),
                onTap: () async {
                  Navigator.of(context).pop();

                  if (await canLaunch(
                      "https://childrenforenvironment.com/terms_of_use")) {
                    await launch(
                        "https://childrenforenvironment.com/terms_of_use");
                  } else {
                    throw 'Could not launch ';
                  }
                },
              ),
              Divider(height: 3.0),
              ListTile(
                leading: Icon(Icons.disc_full),
                title: Text('Disclaimer', style: TextStyle(fontSize: 18)),
                onTap: () {
                  Navigator.of(context).pop();
                  // Here you can give your route to navigate
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (BuildContext context) => DisclaimerScreen(),
                    ),
                  );
                },
              ),
              Divider(height: 3.0),
              ListTile(
                leading: Icon(Icons.mail_outline_outlined),
                title:
                    Text('Report a Tech Issue', style: TextStyle(fontSize: 18)),
                onTap: () async {
                  try {
                    final Email email = Email(
                      body: '',
                      subject: '',
                      recipients: ['techsupport@childrenforenvironment.com'],
                      cc: [],
                      bcc: [],
                      attachmentPaths: [],
                      isHTML: false,
                    );

                    await FlutterEmailSender.send(email);
                  } on PlatformException catch (err) {
                    print("PlatformException new card : " + err.toString());
                  } catch (err) {
                    print("new card : " + err.toString());
                  }
                },
              ),
              Divider(height: 3.0),
              Visibility(
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Logout', style: TextStyle(fontSize: 18)),
                  onTap: () async {
                    // Here you can give your route to navigate
                    NetworkUtil.isLogin = false;
                    NetworkUtil.isSocialLogin = false;
                    NetworkUtil.isSubScribedUser = true;
                    NetworkUtil.isAdult = false;
                    NetworkUtil.subscription_end_date = '';

                    prefs.setBool('isLogin', false);
                    await secureStorage.deleteSecureData("password");
                    prefs.clear();
                    Navigator.pushReplacement(
                      context,
                      CupertinoPageRoute(
                        builder: (BuildContext context) => const WelcomeScreen(),
                      ),
                    );
                  },
                ),
                visible: NetworkUtil.isLogin,
              ),
            ],
          ),
          // ),
        ),
        onDrawerChanged: (isOpen) {
          // write your callback implementation here
          //print('drawer callback isOpen=$isOpen');
          setState(() {
            _filtercat.text = '';
            isSearchCalled = false;
            clearSearch();
          });
        },
        body: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(12),
              color: Color(0xffFCD800),
              child: Card(
                elevation: 6,
                child: TextFormField(
                  controller: _filtercat,
                  focusNode: focusNode,
                  cursorColor: Colors.transparent,
                  //textAlign: TextAlign.center,
                  //textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                      //filled: true,
                      //fillColor: Colors.white,
                      contentPadding: EdgeInsets.fromLTRB(20.0, 13.0, 20.0, 10.0),
                      prefixIcon: Icon(Icons.search),
                      //contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      //focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      // border: OutlineInputBorder(
                      //   borderSide: const BorderSide(
                      //       color: Colors.white, width: 0.0),
                      // ),
                      hintText: '',
                      suffixIcon: _filtercat.text.length > 0
                          ? IconButton(
                              onPressed: clearSearch, icon: Icon(Icons.clear))
                          : null),
                  //onChanged: onItemChanged,
                ),
                //),
              ),
            ),
            Expanded(
              child: Stack(
                  //shrinkWrap: true,
                  children: isSearchCalled == false
                      ? <Widget>[
                          // RefreshIndicator(
                          //   key: _refreshIndicatorKey,
                          //   onRefresh: _refresh,
                          //   child:
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            child: FutureBuilder<categoriesListModel>(
                                future: categotiesListFuture,
                                builder: (context, snapshot) {
                                  // to show progress loading view add switch statment to handle connnection states.
                                  switch (snapshot.connectionState) {
                                    case ConnectionState.waiting:
                                      {
                                        // here we are showing loading view in waiting state.
                                        return loadingView();
                                      }
                                    case ConnectionState.active:
                                      {
                                        break;
                                      }
                                    case ConnectionState.done:
                                      {
                                        // in done state we will handle the snapshot data.
                                        // if snapshot has data show list else set you message.
                                        //print("snapshot done dash" + snapshot.data!.toString());
                                        if (snapshot.hasData) {
                                          // hasdata same as data!=null
                                          if (categoryListView != null) {
                                            if (categoryListView!.length > 0) {
                                              // here inflate data list
                                              return GridView.builder(
                                                  //scrollDirection: Axis.vertical,
                                                  shrinkWrap: true,
                                                  physics: ScrollPhysics(),
                                                  keyboardDismissBehavior:
                                                      ScrollViewKeyboardDismissBehavior
                                                          .onDrag,
                                                  itemCount:
                                                      categoryListView!.length,
                                                  gridDelegate:
                                                      SliverGridDelegateWithFixedCrossAxisCount(
                                                    childAspectRatio:
                                                        8.0 / 10.0,
                                                    crossAxisCount: 2,
                                                  ),
                                                  itemBuilder:
                                                      (context, index) {
                                                    return GestureDetector(
                                                        behavior:
                                                            HitTestBehavior
                                                                .opaque,
                                                        onPanDown: (_) {
                                                          FocusScope.of(context)
                                                              .requestFocus(
                                                                  FocusNode());
                                                        },
                                                        onTap: () {
                                                          setState(() {
                                                            // ontap of each card, set the defined int to the grid view index

                                                            if(NetworkUtil.isLogin)
                                                            {
                                                              if (NetworkUtil
                                                                  .isSubScribedUser) {
                                                                Navigator.push(
                                                                    context,
                                                                    CupertinoPageRoute(
                                                                        builder: (context) =>
                                                                            categoryContent(
                                                                              categoriesModel_:
                                                                              categoryListView![index],
                                                                            )));
                                                              } else {
                                                                try
                                                                {
                                                                  if (Platform.isAndroid) {
                                                                    Navigator.push(
                                                                      context,
                                                                      CupertinoPageRoute(
                                                                        builder: (BuildContext context) => WebViewEx(),
                                                                      ),
                                                                    );
                                                                  } else if (Platform.isIOS) {
                                                                    Navigator.push(
                                                                      context,
                                                                      CupertinoPageRoute(
                                                                        builder: (BuildContext context) => IosPayment(),
                                                                      ),
                                                                    );
                                                                  }
                                                                } on PlatformException {
                                                                  print('Failed to get platform version');
                                                                }

                                                              }
                                                            }
                                                            else
                                                            {
                                                              showAlertLogin(context);
                                                            }

                                                          });
                                                        },
                                                        child: generateColum(
                                                            categoryListView![
                                                                index]));
                                                  });
                                            } else {
                                              // display message for empty data message.
                                              return noDataView(
                                                  "No data found");
                                            }
                                          } else {
                                            // display error message if your list or data is null.
                                            return noDataView("No data found");
                                          }
                                        } else if (snapshot.hasError) {
                                          // display your message if snapshot has error.
                                          return noDataView("No data found");
                                        } else {
                                          return noDataView("No data found");
                                        }
                                        break;
                                      }
                                    case ConnectionState.none:
                                      {
                                        break;
                                      }
                                  }
                                  return loadingView();
                                }),
                          ),
                          //),
                        ]
                      : <Widget>[
                          Container(
                            padding: EdgeInsets.fromLTRB(0, 5, 0, 5),
                            child: FutureBuilder<detailListModel>(
                                future: detailItems,
                                builder: (context, snapshot) {
                                  // to show progress loading view add switch statment to handle connnection states.
                                  //print("snapshot" + snapshot.toString());
                                  switch (snapshot.connectionState) {
                                    case ConnectionState.waiting:
                                      {
                                        // here we are showing loading view in waiting state.
                                        return loadingView();
                                      }
                                    case ConnectionState.active:
                                      {
                                        break;
                                      }
                                    case ConnectionState.done:
                                      {
                                        if (snapshot.hasData) {
                                          // hasdata same as data!=null
                                          if (detailItemsListView! != null) {
                                            if (detailItemsListView!.length >
                                                0) {
                                              // here inflate data list
                                              return ListView.builder(
                                                shrinkWrap: true,
                                                scrollDirection:
                                                    scrollDirection,
                                                controller: _sc,
                                                keyboardDismissBehavior:
                                                    ScrollViewKeyboardDismissBehavior
                                                        .onDrag,
                                                itemCount: 1,
                                                itemBuilder: (context, index) {
                                                  if (openLastindex == -1) {
                                                    //setState(() {
                                                    detailItemsListView![0]
                                                        .isExpanded = true;
                                                    openLastindex = 0;

                                                    //});
                                                  }
                                                  return Padding(
                                                    padding:
                                                        EdgeInsets.fromLTRB(
                                                            0, 0, 0, 0),
                                                    child: ExpansionPanelList(
                                                      key: itemKey,
                                                      expansionCallback:
                                                          (int index,
                                                              bool isExpanded) {
                                                        setState(() {
                                                          if (openLastindex >
                                                                  -1 &&
                                                              openLastindex ==
                                                                  index) {
                                                            detailItemsListView![
                                                                        index]
                                                                    .isExpanded =
                                                                !detailItemsListView![
                                                                        index]
                                                                    .isExpanded!;
                                                            _sc.animateTo(
                                                                _height * index,
                                                                duration: Duration(
                                                                    milliseconds:
                                                                        500),
                                                                curve: Curves
                                                                    .fastOutSlowIn);
                                                          } else if (openLastindex >
                                                                  -1 &&
                                                              openLastindex !=
                                                                  index) {
                                                            detailItemsListView![
                                                                    openLastindex]
                                                                .isExpanded = false;
                                                            detailItemsListView![
                                                                        index]
                                                                    .isExpanded =
                                                                true;
                                                            _sc.animateTo(
                                                                _height * index,
                                                                duration: Duration(
                                                                    milliseconds:
                                                                        500),
                                                                curve: Curves
                                                                    .fastOutSlowIn);
                                                          }
                                                          openLastindex = index;
                                                        });
                                                      },
                                                      children:
                                                          detailItemsListView!.map(
                                                              (ExpansionpanelItem
                                                                  item) {
                                                        return ExpansionPanel(
                                                          canTapOnHeader: true,
                                                          headerBuilder:
                                                              (BuildContext
                                                                      context,
                                                                  bool
                                                                      isExpanded) {
                                                            return ListTile(
                                                                //leading: item.leading,
                                                                title: Text(
                                                              item.title!,
                                                              textAlign:
                                                                  TextAlign
                                                                      .left,
                                                              style: TextStyle(
                                                                fontSize: 16.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ));
                                                          },
                                                          isExpanded:
                                                              item.isExpanded!,
                                                          body: Padding(
                                                            //EdgeInsets.all(10),
                                                            padding: EdgeInsets
                                                                .fromLTRB(
                                                                    0, 0, 0, 0),
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: <
                                                                  Widget>[
                                                                new Divider(
                                                                  color: Color(
                                                                      0xff919191),
                                                                ),
                                                                Align(
                                                                  alignment:
                                                                      Alignment
                                                                          .topRight,
                                                                  child: Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .end,
                                                                    children: <
                                                                        Widget>[
                                                                      Align(
                                                                        alignment:
                                                                            Alignment.topRight,
                                                                        child:
                                                                            Padding(
                                                                          //EdgeInsets.all(10),
                                                                          padding: EdgeInsets.fromLTRB(
                                                                              0,
                                                                              0,
                                                                              30,
                                                                              0),
                                                                          child:
                                                                              IconButton(
                                                                            icon: (item.is_favorite == 1
                                                                                ? Icon(Customicons.heart, color: Color(0xffFF621C))
                                                                                : Icon(Customicons.fav)),
                                                                            onPressed:
                                                                                () {
                                                                              AddRemoveFavorite(item.id, item.is_favorite);
                                                                            },
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                Container(
                                                                  alignment:
                                                                      Alignment
                                                                          .center,
                                                                  child:
                                                                      CachedNetworkImage(
                                                                    placeholder:
                                                                        (context,
                                                                                url) =>
                                                                            CircularProgressIndicator(),
                                                                    imageUrl: item
                                                                        .photo!,
                                                                    httpHeaders:
                                                                        headers,
                                                                    filterQuality:
                                                                        FilterQuality
                                                                            .medium,
                                                                    //fit: BoxFit.cover,
                                                                  ),
                                                                  //child : Image.asset('assets/one.jpg'),
                                                                  //elevation: 5,
                                                                  //margin: EdgeInsets.all(10),
                                                                  //),
                                                                ),
                                                                //),
                                                              ],
                                                            ),
                                                          ),
                                                        );
                                                      }).toList(),
                                                    ),
                                                  );
                                                  //}
                                                },
                                              );
                                            } else {
                                              // display message for empty data message.

                                              if (isSearchLoader) {
                                                return noDataView(
                                                    "Searching...");
                                              } else {
                                                return noDataView(
                                                    "No Record found");
                                              }
                                            }
                                          } else {
                                            // display error message if your list or data is null.
                                            return noDataView(
                                                "No Record found");
                                          }
                                        } else if (snapshot.hasError) {
                                          // display your message if snapshot has error.
                                          return noDataView(
                                              "Something went wrong");
                                        } else {
                                          return noDataView(
                                              "Something went wrong");
                                        }
                                        break;
                                      }
                                    case ConnectionState.none:
                                      {
                                        break;
                                      }
                                  }
                                  return loadingView();
                                }),
                          ),
                        ]),
            ),
            //  ],
            //),
          ],
        ),
        //),
        //Container (
        floatingActionButton: FloatingActionButton(
          backgroundColor: Color(0xffFF621C),
          //splashColor: Colors.black,
          onPressed: () {
            setState(() {
              _filtercat.text = '';
              isSearchCalled = false;
              focusNode.unfocus();
            });

            if(NetworkUtil.isLogin)
            {
              if (NetworkUtil.isSubScribedUser) {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (BuildContext context) => FastFactsScreen(),
                  ),
                );
              }else
              {
                try
                {
                  if (Platform.isAndroid) {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (BuildContext context) => WebViewEx(),
                      ),
                    );
                  } else if (Platform.isIOS) {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (BuildContext context) => IosPayment(),
                      ),
                    );
                  }
                } on PlatformException {
                  print('Failed to get platform version');
                }

                Fluttertoast.showToast(
                    msg: NetworkUtil.subscription_end_date == ''
                        ? 'Start your subscription'
                        : 'Renew Your Membership',
                    toastLength: Toast.LENGTH_LONG,
                    gravity: ToastGravity.SNACKBAR,
                    timeInSecForIosWeb: 1,
                    backgroundColor: Color(0xffE74C3C),
                    textColor: Colors.white,
                    fontSize: 16.0);
              }
            }
            else
            {
              showAlertLogin(context);
            }

          },
          hoverElevation: 1.5,
          shape: StadiumBorder(side: BorderSide(color: Colors.white, width: 2)),
          elevation: 1.5,
          child: Icon(
            Customicons.bulb,
            //color: _foregroundColor,
          ),
        ),
        //),
        bottomNavigationBar:
            // SizedBox(
            //   height: 70,
            //   child:
            BottomNavigationBar(
          elevation: 20,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Customicons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Customicons.feed),
              label: 'Feed',
            ),
            BottomNavigationBarItem(
              icon: Icon(Customicons.fav),
              label: 'Favorites',
            ),
            BottomNavigationBarItem(
              icon: Icon(Customicons.profile),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          backgroundColor: Colors.white,
          unselectedItemColor: Color(0xff000000),
          selectedItemColor: Color(0xff159591),
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
        ),
        //),
      ),
    );
  }

  Widget generateColum(categoriesModel item) => Padding(
      //EdgeInsets.all(10),
      padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Card(
          semanticContainer: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                  child: Container(
                alignment: Alignment.center,
                margin: const EdgeInsets.fromLTRB(30, 30, 30, 0),
                child: CachedNetworkImage(
                  placeholder: (context, url) => CircularProgressIndicator(),
                  errorWidget: (context, url, error) =>
                      Image.asset("assets/no_image.png"),
                  imageUrl: item.category_cover_image!,
                  fit: BoxFit.contain,
                  //httpHeaders: headers,
                ),
              )),
              Padding(
                padding: EdgeInsets.all(10.0),
                child: Center(
                  child: Text(
                    item.categoryName!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18.0),
                  ),
                ),
              ),
            ],
          )));

  Widget noDataView(String msg) => Center(
        child: Text(
          msg,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      );

  // Progress indicator widget to show loading.
  Widget loadingView() => Center(
        child: CircularProgressIndicator(
          backgroundColor: Colors.red,
        ),
      );

  Future<Null> _refresh() {
    return _netUtil.isConnected().then((internet) {
      if (internet) {
        _filtercat.clear();
        focusNode.unfocus();
        // set state while we fetch data from API
        setState(() {
          // calling API to show the data
          // you can also do it with any button click.
          categoryListView = <categoriesModel>[];
          filtercatListView = <categoriesModel>[];
          categotiesListFuture = getcategoriesList();
        });
      } else {
        NetworkUtil.showDialogNoInternet(
            'You are disconnected to the Internet.',
            'Please check your internet connection',
            context);
      }
    });
  }

  clearSearch() {
    focusNode.unfocus();
    _filtercat.clear();
  }

  @override
  void dispose() {
    _filtercat.dispose();
    super.dispose();
  }

  shareApp(BuildContext context) async {
    final RenderBox box = context.findRenderObject() as RenderBox;

    await Share.share(
        'hey! check out this new app android : https://play.google.com/store/apps/details?id=com.children.cfe&hl=en  ios : https://apps.apple.com/us/app/children-for-environment/id1609925887',
        subject: 'Children For Environment',
        sharePositionOrigin: box.globalToLocal(Offset.zero) & box.size);
  }

  showAlertLogin(BuildContext context) {
    Widget continueButton = TextButton(
      child: Text("OK"),
      onPressed: () {
        Navigator.pushReplacement(
                    context,
                    CupertinoPageRoute(
                        builder: (context) => const WelcomeScreen()));
      },
    );

    Widget cancelButton = TextButton(
        child: Text("Cancel"),
        onPressed: () {
          Navigator.of(context).pop();
        },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Alert"),
      content: Text("Please sign in to the application to access the features."),
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

  showAlertDialog(BuildContext context) {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("Cancel"),
      onPressed: () {
        SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      },
    );
    Widget continueButton = TextButton(
      child: Text("Update"),
      onPressed: () {
        StoreRedirect.redirect();
        // StoreRedirect.redirect(
        //     androidAppId: "com.tatacommunications.eptw", iOSAppId: "585027354");
        //Navigator.of(context, rootNavigator: true).pop();
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("App Update"),
      content: Text("New Version of App available please update?"),
      actions: [
        cancelButton,
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

  Future<detailListModel> getAppSearchList(int pageindex) async
  {
    if(NetworkUtil.isLogin)
    {
      //print("pageindex : " + pageindex.toString());
      if (!isLoadingLazy && pageindex > 0) {
        setState(() {
          isLoadingLazy = true;
        });
      }

      NetworkUtil.getAppSearch = "api/posts/search/" +
          pageindex.toString() +
          "/" +
          pageCount.toString() +
          "?search=" +
          _filtercat.text.toString();
      return _netUtil.get(NetworkUtil.getAppSearch, true).then((dynamic res) {
        //json.decode used to decode response.body(string to map)
        //print(res['posts'].toString());

        if (res != null && res["MessageType"] == 1) {
          getDetailList(res['posts']);
          return detailListModel.fromJson(res['posts']);
          //return getDetailList(res['posts']);
        } else if (res != null && res["MessageType"] == 0) {
          Fluttertoast.showToast(
              msg: res["Message"],
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.SNACKBAR,
              timeInSecForIosWeb: 1,
              backgroundColor: Color(0xffE74C3C),
              textColor: Colors.white,
              fontSize: 16.0);

          return detailListModel.fromJson([]);
        } else if (res != null && res["MessageType"] == -1) {

          var msg = res["Message"];
          if(res["Message"].toString().toLowerCase().contains("renew")){
            if(NetworkUtil.subscription_end_date == ''){
              msg = 'Start your subscription';
            }else{
              msg = 'Renew Your Membership';
            }

          }
          Fluttertoast.showToast(
              msg: msg,
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.SNACKBAR,
              timeInSecForIosWeb: 1,
              backgroundColor: Color(0xffE74C3C),
              textColor: Colors.white,
              fontSize: 16.0);

          return detailListModel.fromJson([]);
        } else {
          Fluttertoast.showToast(
              msg: 'Something went wrong.',
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.SNACKBAR,
              timeInSecForIosWeb: 1,
              backgroundColor: Color(0xffE74C3C),
              textColor: Colors.white,
              fontSize: 16.0);

          return detailListModel.fromJson([]);
          //return getDetailList(res['posts']);
        }
      });
    }
    else
    {
      showAlertLogin(context);
      return detailListModel.fromJson([]);
    }
  }

  void getDetailList(List<dynamic> parsedJson) {
    //List<ExpansionpanelItem>? detailList = <ExpansionpanelItem>[];
    for (var v in parsedJson) {
      detailItemsListView!.add(ExpansionpanelItem.fromJson(v));
    }

    //print("list : " + detailItemsListView![0].id.toString());

    setState(() {
      isLoadingLazy = false;

      //print("page : " + page.toString() + parsedJson.length.toString());
      if (parsedJson.length < 10) {
        _hasMore = false;
      } else {
        _hasMore = true;
        page = detailItemsListView!.length;
      }

      //print("page : " + page.toString());
    });
  }

  AddRemoveFavorite(int? id, int? is_favorite) {
    //print("fav open : " + openLastindex.toString() + "index clicked : " + index.toString());
    if (is_favorite == 1) {
      // setState(() {
      //   _submit = true;
      // });

      NetworkUtil.RemoveFromFavorite = "api/unbookmark/" + id.toString();
      return _netUtil
          .get(NetworkUtil.RemoveFromFavorite, true)
          .then((dynamic res) {
        // setState(() {
        //   _submit = false;
        // });

        if (res != null && res["MessageType"] == 1) {
          Fluttertoast.showToast(
              msg: res["Message"],
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.SNACKBAR,
              timeInSecForIosWeb: 1,
              backgroundColor: Color(0xff69F0AE),
              textColor: Color(0xff19442C),
              fontSize: 16.0);

          setState(() {
            detailItemsListView![openLastindex].is_favorite = 0;
          });
        } else {
          Fluttertoast.showToast(
              msg: res["Message"],
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.SNACKBAR,
              timeInSecForIosWeb: 1,
              backgroundColor: Color(0xff69F0AE),
              textColor: Color(0xff19442C),
              fontSize: 16.0);
        }
      });
    } else {
      NetworkUtil.AddToFavorite = "api/bookmark/" + id.toString();
      return _netUtil.get(NetworkUtil.AddToFavorite, true).then((dynamic res) {
        if (res != null && res["MessageType"] == 1) {
          Fluttertoast.showToast(
              msg: res["Message"],
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.SNACKBAR,
              timeInSecForIosWeb: 1,
              backgroundColor: Color(0xff69F0AE),
              textColor: Color(0xff19442C),
              fontSize: 16.0);

          setState(() {
            detailItemsListView![openLastindex].is_favorite = 1;
          });
        } else {
          Fluttertoast.showToast(
              msg: res["Message"],
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.SNACKBAR,
              timeInSecForIosWeb: 1,
              backgroundColor: Color(0xff69F0AE),
              textColor: Color(0xff19442C),
              fontSize: 16.0);
        }
      });
    }
  }

  // onItemChanged(String value) {
  //
  //   setState(() {
  //
  //     if(value != null && value.length > 0){
  //       print("search test : " + value);
  //       categoryListView = filtercatListView!.where((i) => i.categoryName.toString().toLowerCase().contains(value.toLowerCase())).toList();
  //     }else{
  //       categoryListView = filtercatListView;
  //     }
  //
  //
  //   });
  // }
}
