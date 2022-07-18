import 'package:CFE/Networking/networkUtil.dart';
import 'package:CFE/models/ExpansionpanelItem.dart';
import 'package:CFE/models/categoriesModel.dart';
import 'package:CFE/models/detailListModel.dart';
import 'package:async/async.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
//import 'package:scroll_to_index/scroll_to_index.dart';
// import 'package:vector_math/vector_math.dart' as vec;
import '../icons.dart';
import 'IosPayment.dart';
import 'Login_screen.dart';
import 'PaymentSelection.dart';
import 'dart:io' show Platform;
import 'package:share_plus/share_plus.dart';

import 'WebViewScreen.dart';

class categoryContent extends StatefulWidget {
  categoriesModel categoriesModel_;

  categoryContent({Key? key, required this.categoriesModel_}) : super(key: key);

  @override
  Expansionpaneltate createState() =>
      Expansionpaneltate(categoriesModel_: this.categoriesModel_);
}

class Expansionpaneltate extends State<categoryContent> {
  late SharedPreferences prefs;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();
  bool isLoaded = true;
  int openLastindex = -1;
  bool _submit = false;

  final scrollDirection = Axis.vertical;

  bool isSearchCalled = false;
  bool isSearchLoader = false;
  String previousSearchText = '';
  Timer? periodicTimer;

  NetworkUtil _netUtil = new NetworkUtil();
  int page = 0;
  int pageCount = 10;
  ScrollController _sc = new ScrollController();
  bool isLoadingLazy = false;
  bool _hasMore = true;
  bool isSearchClick = false;
  String? categoryName = '';
  final _height = 60.0;

  Map<String, String> headers = {
    "Authorization": "Bearer " + NetworkUtil.token
  };
  List<ExpansionpanelItem>? detailItemsListView = <ExpansionpanelItem>[];
  List<ExpansionpanelItem>? filtereddata = <ExpansionpanelItem>[];
  List<ExpansionpanelItem>? temppagedata = <ExpansionpanelItem>[];

  Future<detailListModel>? detailItems;
  late RenderBox box;

  Icon actionIcon = new Icon(Icons.search);
  final TextEditingController _filter = new TextEditingController();
  String _searchText = "";

  categoriesModel? categoriesModel_;

  Expansionpaneltate({this.categoriesModel_});

  @override
  void initState() {

    super.initState();
    _netUtil.isConnected().then((internet) {
      if (internet) {
        // set state while we fetch data from API
        setState(() {
          // calling API to show the data
          detailItems = getcategoriesDetail(page);

          // for converting Future<T> to List
          // getcategoriesDetail().then((resultat){
          //   setState(() => detailItems = resultat);
          //   });
        });
      } else {
        NetworkUtil.showDialogNoInternet(
            'You are disconnected to the Internet.',
            'Please check your internet connection',
            context);
      }
    });

    _filter.addListener(() {

      if (_filter.text.isEmpty) {

        setState(() {
          detailItemsListView = <ExpansionpanelItem>[];
          isSearchCalled = false;
          //_filter.clear();
          if(!isSearchClick){
            detailItems = getcategoriesDetail(0);
          }

        });

      } else {

        if(previousSearchText != _filter.text){

          previousSearchText = _filter.text;

          setState(() {

            if(periodicTimer != null){
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
      if (_sc.position.pixels == _sc.position.maxScrollExtent) {
        //print("lazy load listener called");

        if (_hasMore) {
          //print("lazy load called");
          if(isSearchCalled){
            getAppSearchList(page);
          }else{
            Future<detailListModel> data = getcategoriesDetail(page);
          }

        }

      }
    });
  }

  Future<detailListModel> getAppSearchList(int pageindex) async {
    //print("pageindex search : " + pageindex.toString());
    if (!isLoadingLazy && pageindex > 0) {
      setState(() {
        isLoadingLazy = true;
      });
    }

    NetworkUtil.getAppSearch = "api/posts/search/" + pageindex.toString() + "/" + pageCount.toString() + "?search=" + _filter.text.toString();
    return _netUtil
        .get(NetworkUtil.getAppSearch, true)
        .then((dynamic res) {
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

        Fluttertoast.showToast(
            msg: res["Message"],
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

  Future<detailListModel> getcategoriesDetail(int pageindex) async {
    //print("pageindex : " + pageindex.toString());
    if (!isLoadingLazy && pageindex > 0) {
      setState(() {
        isLoadingLazy = true;
      });
    }

    if (NetworkUtil
        .isSubScribedUser)
    {
      NetworkUtil.getCategoriesdetail = "api/category/" +
          widget.categoriesModel_.id.toString() +
          "/posts/" +
          pageindex.toString() +
          "/" +
          pageCount.toString();
    }
    else {
      NetworkUtil.getCategoriesdetail = "api/category/" +
          widget.categoriesModel_.id.toString() +
          "/free-posts";
    }

    return _netUtil
        .get(NetworkUtil.getCategoriesdetail, true)
        .then((dynamic res) {
      //json.decode used to decode response.body(string to map)
      //print(res['posts'].toString());
      print("UrlD = "+NetworkUtil.getCategoriesdetail);
      print("UrlD_Res = "+res.toString());

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
          CupertinoPageRoute<void>(
            builder: (BuildContext context) => const PaymentSelection(),
          ),
        );

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

  @override
  void dispose() {
    _filter.dispose();
    _sc.dispose();
    super.dispose();
  }

  void getDetailList(List<dynamic> parsedJson) {
    //List<ExpansionpanelItem>? detailList = <ExpansionpanelItem>[];
    for (var v in parsedJson) {
      detailItemsListView!.add(ExpansionpanelItem.fromJson(v));
    }

    //print("list : " + detailItemsListView!.length.toString());

    setState(() {
      isLoadingLazy = false;
      //detailItems = futureGroup.future.then((value) =>  detailListModel.fromJson(value));

      //print("data length : " + parsedJson.length.toString());
      if (parsedJson.length < 10) {
        _hasMore = false;
      } else {
        _hasMore = true;
        page = detailItemsListView!.length;
      }
    });

  }

  onItemChanged(String value) {

    // setState(() {
    //   openLastindex = -1;
    //   for (var i = 0; i < detailItemsListView!.length; i++) {
    //     detailItemsListView![i].isExpanded = false;
    //   }
    //
    //   //print("search test : " + value);
    //   detailItemsListView = filtereddata!
    //       .where((i) =>
    //           (i.title.toString().toLowerCase().contains(value.toLowerCase()) ||
    //               i.description
    //                   .toString()
    //                   .toLowerCase()
    //                   .contains(value.toLowerCase())))
    //       .toList();
    // });
  }

  Widget appBarTitle = Text("CFE",
      style: const TextStyle(
          color: Color(0xff000000), fontWeight: FontWeight.bold));

  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(
        body: Stack(
          children:
              // Map View
              isLoaded == true
                  ? <Widget>[
                      Container(
                        child: Scaffold(
                          appBar: new AppBar(
                              centerTitle: false,
                              title: isSearchClick == true
                                  ? appBarTitle
                                  : Text(widget.categoriesModel_.categoryName!,
                                      style: const TextStyle(
                                          color: Color(0xff000000),
                                          fontWeight: FontWeight.bold)),
                              backgroundColor: Color(0xffFCD800),
                              iconTheme: IconThemeData(color: Colors.black),
                              actions: <Widget>[
                                new IconButton(
                                  icon: actionIcon,
                                  onPressed: () {
                                    setState(() {
                                      isSearchClick = true;
                                      if (this.actionIcon.icon ==
                                          Icons.search) {
                                        this.actionIcon = new Icon(Icons.close);
                                        this.appBarTitle = new TextField(
                                          controller: _filter,
                                          autofocus: true,
                                          style: new TextStyle(
                                            color: Colors.black,
                                          ),
                                          decoration: new InputDecoration(
                                              prefixIcon: new Icon(Icons.search,
                                                  color: Colors.black),
                                              hintText: "Search...",
                                              hintStyle: new TextStyle(
                                                  color: Colors.black)),
                                          //onChanged: onItemChanged,
                                        );
                                      } else {
                                        isSearchClick = false;
                                        this.actionIcon =
                                            new Icon(Icons.search);
                                        this.appBarTitle = new Text(
                                            widget
                                                .categoriesModel_.categoryName!,
                                            style: const TextStyle(
                                                color: Color(0xff000000),
                                                fontWeight: FontWeight.bold));
                                        setState(() {
                                          //detailItemsListView = temppagedata;
                                          _filter.text = '';
                                        });
                                        //_filter.clear();
                                      }
                                    });
                                  },
                                ),
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
                              ]),
                          body:
                              // RefreshIndicator(
                              //   key: _refreshIndicatorKey,
                              //   onRefresh: _refresh,
                              ModalProgressHUD(
                                  child: Container(
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
                                                // in done state we will handle the snapshot data.
                                                // if snapshot has data show list else set you message.
                                                //print("snapshot done" + detailItemsListView!.length.toString());
                                                //print("snapshot data" + snapshot.data!.detaildataList![1].id.toString());

                                                if (snapshot.hasData) {
                                                  // hasdata same as data!=null
                                                  if (detailItemsListView! !=
                                                      null) {
                                                    if (detailItemsListView!
                                                            .length >
                                                        0) {
                                                      // here inflate data list
                                                      return ListView.builder(
                                                        scrollDirection:
                                                            scrollDirection,
                                                        controller: _sc,
                                                        keyboardDismissBehavior:
                                                            ScrollViewKeyboardDismissBehavior
                                                                .onDrag,
                                                        itemCount: 1,
                                                        itemBuilder:
                                                            (context, index) {
                                                          if (openLastindex ==
                                                                  -1 &&
                                                              _filter.text
                                                                  .isEmpty) {
                                                            //setState(() {
                                                            detailItemsListView![
                                                                        0]
                                                                    .isExpanded =
                                                                true;
                                                            openLastindex = 0;

                                                            //});
                                                          }
                                                          return Padding(
                                                            padding: EdgeInsets
                                                                .fromLTRB(
                                                                    0, 0, 0, 0),
                                                            child:
                                                                ExpansionPanelList(
                                                              expansionCallback:
                                                                  (int index,
                                                                      bool
                                                                          isExpanded) {
                                                                //_sc.jumpTo(index.toDouble());
                                                                // print("openLastindex 23" +
                                                                //     openLastindex
                                                                //         .toString() +
                                                                //     "index 23" +
                                                                //     index
                                                                //         .toString());
                                                                setState(() {
                                                                  //detailItemsListView![0].isExpanded = false;
                                                                  // if(openLastindex == -1){
                                                                  //   detailItemsListView![index].isExpanded = true;
                                                                  // }
                                                                  // else
                                                                  if (openLastindex >
                                                                          -1 &&
                                                                      openLastindex ==
                                                                          index) {
                                                                    detailItemsListView![
                                                                            index]
                                                                        .isExpanded = !detailItemsListView![
                                                                            index]
                                                                        .isExpanded!;
                                                                    _sc.animateTo(
                                                                        _height *
                                                                            index,
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
                                                                        .isExpanded = true;
                                                                    _sc.animateTo(
                                                                        _height *
                                                                            index,
                                                                        duration: Duration(
                                                                            milliseconds:
                                                                                500),
                                                                        curve: Curves
                                                                            .fastOutSlowIn);
                                                                  }
                                                                  openLastindex =
                                                                      index;
                                                                });
                                                              },
                                                              children:
                                                                  detailItemsListView!.map(
                                                                      (ExpansionpanelItem
                                                                          item) {
                                                                return ExpansionPanel(
                                                                  canTapOnHeader:
                                                                      true,
                                                                  headerBuilder:
                                                                      (BuildContext
                                                                              context,
                                                                          bool
                                                                              isExpanded) {
                                                                    return ListTile(
                                                                        //leading: item.leading,
                                                                        title:
                                                                            Text(
                                                                      item.title!,
                                                                      textAlign:
                                                                          TextAlign
                                                                              .left,
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            16.0,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                    ));
                                                                  },
                                                                  isExpanded: item
                                                                      .isExpanded!,
                                                                  body: Padding(
                                                                    //EdgeInsets.all(10),
                                                                    padding: EdgeInsets
                                                                        .fromLTRB(
                                                                            0,
                                                                            0,
                                                                            0,
                                                                            0),
                                                                    child:
                                                                        Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      children: <
                                                                          Widget>[
                                                                        new Divider(
                                                                          color:
                                                                              Color(0xff919191),
                                                                        ),
                                                                        Align(
                                                                          alignment:
                                                                              Alignment.topRight,
                                                                          child:
                                                                              Row(
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.end,
                                                                            children: <Widget>[
                                                                              Align(
                                                                                alignment: Alignment.topRight,
                                                                                child: Padding(
                                                                                  //EdgeInsets.all(10),
                                                                                  padding: EdgeInsets.fromLTRB(0, 0, 30, 0),
                                                                                  child: IconButton(
                                                                                    icon: (item.is_favorite == 1 ? Icon(Customicons.heart, color: Color(0xffFF621C)) : Icon(Customicons.fav)),
                                                                                    onPressed: () {
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
                                                                              Alignment.center,
                                                                          child:
                                                                              CachedNetworkImage(
                                                                            placeholder: (context, url) =>
                                                                                CircularProgressIndicator(),
                                                                            imageUrl:
                                                                                item.photo!,
                                                                            httpHeaders:
                                                                                headers,
                                                                            filterQuality:
                                                                                FilterQuality.medium,
                                                                            //fit: BoxFit.cover,
                                                                          ),
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
                                                      if(isSearchLoader){
                                                        return noDataView(
                                                            "Searching...");
                                                      }else{
                                                        return noDataView(
                                                            "No record found");
                                                      }
                                                    }
                                                  } else {
                                                    // display error message if your list or data is null.
                                                    return noDataView(
                                                        "No record found");
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
                                          return noDataView(
                                              "Something went wrong");
                                        }),
                                  ),
                                  inAsyncCall: _submit),
                          //),
                            floatingActionButtonLocation: FloatingActionButtonLocation.miniCenterFloat,
                            floatingActionButton: Visibility(
                              child: FloatingActionButton.extended(
                                backgroundColor: Color(0xffFF621C),
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
                                },
                                // icon: Icon(Icons.add),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14.0),
                                ),
                                label: Text('Read more...',style:  TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
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
                            child: Text(widget.categoriesModel_.categoryName!,
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

  Color hexToColor(String code) {
    return new Color(int.parse(code.substring(1, 7), radix: 16) + 0xFF000000);
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
          detailItemsListView!.clear();
          detailItems = getcategoriesDetail(page);
        });
      } else {
        NetworkUtil.showDialogNoInternet(
            'You are disconnected to the Internet.',
            'Please check your internet connection',
            context);
      }
    });
  }

  Widget _buildProgressIndicator() {
    return new Padding(
      padding: const EdgeInsets.all(8.0),
      child: new Center(
        child: new Opacity(
          opacity: isLoadingLazy ? 1.0 : 00,
          child: new CircularProgressIndicator(),
        ),
      ),
    );
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
      // setState(() {
      //   _submit = true;
      // });

      NetworkUtil.AddToFavorite = "api/bookmark/" + id.toString();
      return _netUtil.get(NetworkUtil.AddToFavorite, true).then((dynamic res) {
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


  shareApp(BuildContext context) async {
    final RenderBox box = context.findRenderObject() as RenderBox;

    await Share.share(
        'hey! check out this new app android : https://play.google.com/store/apps/details?id=com.children.cfe&hl=en  ios : https://apps.apple.com/app/cfe-children-for-environment/id1609925887',
        subject: 'Children For Environment',
        sharePositionOrigin: box.globalToLocal(Offset.zero) & box.size);

  }
}
