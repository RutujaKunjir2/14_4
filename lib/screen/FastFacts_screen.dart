import 'package:CFE/Networking/networkUtil.dart';
import 'package:CFE/models/FastFactsData.dart';
import 'package:CFE/models/fastFactsModel.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:io' show Platform;

import 'IosPayment.dart';
import 'WebViewScreen.dart';

class FastFactsScreen extends StatefulWidget {
  FastFactsScreen({Key? key}) : super(key: key);

  @override
  State<FastFactsScreen> createState() => FastFacts();
}

class FastFacts extends State<FastFactsScreen> {
  late SharedPreferences prefs;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();
  bool isLoaded = true;
  int openLastindex = -1;

  final scrollDirection = Axis.vertical;

  NetworkUtil _netUtil = new NetworkUtil();
  int page = 0;
  int pageCount = 10;
  ScrollController _sc = new ScrollController();
  final itemKey = GlobalKey();
  bool isLoadingLazy = false;
  bool _hasMore = true;
  bool isSearchClick = false;
  String? categoryName = '';
  final _height = 60.0;

  Map<String, String> headers = {
    "Authorization": "Bearer " + NetworkUtil.token
  };
  List<FastFactsData>? factsListView = <FastFactsData>[];

  Future<fastFactsModel>? factItemsFuture;

  Icon actionIcon = new Icon(Icons.search);
  final TextEditingController _filter = new TextEditingController();
  String _searchText = "";

  fastFactsModel? fastFactModel_;

  FastFacts({this.fastFactModel_});

  @override
  void initState() {
    super.initState();
    _netUtil.isConnected().then((internet) {
      if (internet) {
        // set state while we fetch data from API
        setState(() {
          factItemsFuture = getfastFacts(page);
        });
      } else {
        NetworkUtil.showDialogNoInternet(
            'You are disconnected to the Internet.',
            'Please check your internet connection',
            context);
      }
    });

    _sc.addListener(() {
      if (_sc.position.pixels == _sc.position.maxScrollExtent) {
        //print("lazy load listener called");

        if (_hasMore && !isSearchClick) {
          //print("lazy load called");
          Future<fastFactsModel> data = getfastFacts(page);
        }
      }
    });
  }


  Future<fastFactsModel> getfastFacts(int pageindex) async {
    if (!isLoadingLazy && pageindex > 0) {
      setState(() {
        isLoadingLazy = true;
      });
    }

    if (NetworkUtil
        .isSubScribedUser)
    {
      NetworkUtil.getFastFactList =
          "api/fast-facts/" + pageindex.toString() + "/" + pageCount.toString();
    }
    else {
      NetworkUtil.getFastFactList =
          "api/free-fast-facts";
    }

    return _netUtil.get(NetworkUtil.getFastFactList, true).then((dynamic res) {
      //json.decode used to decode response.body(string to map)
      //print(res['posts'].toString());

      if (res != null && res["MessageType"] == 1) {
        getDetailList(res['fast-facts']);
        return fastFactsModel.fromJson(res['fast-facts']);
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

        return fastFactsModel.fromJson([]);
      } else {
        Fluttertoast.showToast(
            msg: 'Something went wrong.',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.SNACKBAR,
            timeInSecForIosWeb: 1,
            backgroundColor: Color(0xffE74C3C),
            textColor: Colors.white,
            fontSize: 16.0);

        return fastFactsModel.fromJson([]);
        //return getDetailList(res['posts']);
      }
    });
  }

  @override
  void dispose() {
    _filter.dispose();
    _sc.dispose();
    super.dispose();
  }

  void getDetailList(List<dynamic> parsedJson) {
    //List<ExpansionpanelItem>? detailList = <ExpansionpanelItem>[];
    for (var v in parsedJson) {
      factsListView!.add(FastFactsData.fromJson(v));
    }

    setState(() {
      isLoadingLazy = false;
      //factItemsFuture = futureGroup.future.then((value) =>  detailListModel.fromJson(value));

      //print("data length : " + parsedJson.length.toString());
      if (parsedJson.length < 10) {
        _hasMore = false;
      } else {
        page = factsListView!.length;
      }

      //temppagedata = factsListView;
    });
  }

  Widget appBarTitle = Text("CFE",
      style: const TextStyle(
          color: Color(0xff000000), fontWeight: FontWeight.bold));

  Widget build(BuildContext context) {
    //Widget appBarTitle = Text(widget.categoriesModel_.categoryName!,style: const TextStyle(color: Color(0xff000000),fontWeight: FontWeight.bold));
    return Container(
      child: Scaffold(
        body: Stack(
          children:
              // Map View
              isLoaded == true
                  ? <Widget>[
                      Container(
                        child: Scaffold(
                          appBar: AppBar(
                            automaticallyImplyLeading: true,
                            leading: IconButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              icon: Icon(Icons.arrow_back),
                            ),
                            backgroundColor: Color(0xffFCD800),
                            title: Text("Fast Facts",
                                style: const TextStyle(
                                    color: Color(0xff000000),
                                    fontWeight: FontWeight.bold)),
                            iconTheme: IconThemeData(color: Colors.black),
                            actions: <Widget>[
                              Visibility(
                                child: Padding(
                                    padding: EdgeInsets.only(right: 20.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        shareApp(context);
                                      },
                                      child: Icon(
                                        Icons.share,
                                        size: 26.0,
                                      ),
                                    )
                                ),
                                visible: true,
                              ),
                            ],
                          ),
                          body:
                              // Expanded(
                              //   child : RefreshIndicator(
                              //     key: _refreshIndicatorKey,
                              //     onRefresh: _refresh, child :
                              Container(
                            padding: const EdgeInsets.all(0.0),
                            child: FutureBuilder<fastFactsModel>(
                                future: factItemsFuture,
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
                                        //print("snapshot done dash" + snapshot.data!.toString());
                                        if (snapshot.hasData) {
                                          // hasdata same as data!=null
                                          if (factsListView != null) {
                                            if (factsListView!.length > 0) {
                                              // here inflate data list
                                              return ListView.builder(
                                                scrollDirection:
                                                    scrollDirection,
                                                controller: _sc,
                                                //keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                                                itemCount:
                                                    factsListView!.length,
                                                itemBuilder: (BuildContext ctx,
                                                    int index) {
                                                  return Container(
                                                    alignment: Alignment.center,
                                                    child: CachedNetworkImage(
                                                      placeholder: (context,
                                                              url) =>
                                                          CircularProgressIndicator(),
                                                      imageUrl:
                                                          factsListView![index]
                                                              .fact_image_url
                                                              .toString(),
                                                      httpHeaders: headers,
                                                      //fit: BoxFit.cover,
                                                    ),
                                                  );
                                                },
                                              );
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
                                  return noDataView("Something went wrong");
                                }),
                          ),
                          //),
                          //   ),
                          floatingActionButton: Visibility(
                            child: FloatingActionButton.extended(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.white,
                              onPressed: () {
                                try
                                {
                                  if (Platform.isAndroid) {
                                    Navigator.push(
                                      context,
                                      CupertinoPageRoute(
                                        builder: (BuildContext context) => WebViewEx(),
                                      ),
                                    );
                                  }
                                  else if (Platform.isIOS) {
                                    Navigator.push(
                                      context,
                                      CupertinoPageRoute(
                                        builder: (BuildContext context) =>
                                            IosPayment(),
                                      ),
                                    );
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

                                } on PlatformException {
                                  print('Failed to get platform version');
                                }
                              },
                              // icon: Icon(Icons.add),
                              label: Text('Read more...',style:  TextStyle(
                                  color: hexToColor("#120BD6"),
                                  fontWeight: FontWeight.normal,
                                  fontSize: 15.0)),
                            ),
                            visible: !NetworkUtil.isSubScribedUser,
                          ),
                        ),
                      ),
                    ]
                  : <Widget>[
                      Container(
                          decoration:
                              const BoxDecoration(color: Color(0xff159591)),
                          padding: const EdgeInsets.all(25),
                          child: Center(
                            child: Text("Favorite",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 48.0)),
                          )),
                    ],
        ),
      ),
    );
  }

  Future<Null> _refresh() {
    //print("refresh call");
    return _netUtil.isConnected().then((internet) {
      if (internet) {
        // set state while we fetch data from API
        setState(() {
          // calling API to show the data
          // you can also do it with any button click.
          page = 0;
          openLastindex = -1;
          factsListView!.clear();
          factItemsFuture = getfastFacts(page);
        });
      } else {
        NetworkUtil.showDialogNoInternet(
            'You are disconnected to the Internet.',
            'Please check your internet connection',
            context);
      }
    });
  }

  Color hexToColor(String code) {
    return new Color(int.parse(code.substring(1, 7), radix: 16) + 0xFF000000);
  }

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

  shareApp(BuildContext context) async {
    final RenderBox box = context.findRenderObject() as RenderBox;

    await Share.share(
        'hey! check out this new app android : https://play.google.com/store/apps/details?id=com.children.cfe&hl=en  ios : https://apps.apple.com/app/cfe-children-for-environment/id1609925887',
        subject: 'Children For Environment',
        sharePositionOrigin: box.globalToLocal(Offset.zero) & box.size);
  }
}
