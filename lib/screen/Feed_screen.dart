import 'package:CFE/Networking/networkUtil.dart';
import 'package:CFE/models/ExpansionpanelItem.dart';
import 'package:CFE/models/categoriesModel.dart';
import 'package:CFE/models/detailListModel.dart';
import 'package:async/async.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
//import 'package:scroll_to_index/scroll_to_index.dart';
import '../icons.dart';
import 'Login_screen.dart';

class FeedScreen extends StatefulWidget {
  FeedScreen({Key? key}) : super(key: key);

  @override
  FeedScreenList createState() => FeedScreenList();
}

class FeedScreenList extends State<FeedScreen> {
  late SharedPreferences prefs;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();
  bool isLoaded = true;
  int openLastindex = -1;
  int totalfeedcount = 0;

  final scrollDirection = Axis.vertical;

  NetworkUtil _netUtil = new NetworkUtil();
  int page = 1;
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
  List<ExpansionpanelItem>? detailItemsListView = <ExpansionpanelItem>[];
  List<ExpansionpanelItem>? filtereddata = <ExpansionpanelItem>[];
  List<ExpansionpanelItem>? temppagedata = <ExpansionpanelItem>[];

  Future<detailListModel>? detailItems;

  Icon actionIcon = new Icon(Icons.search);
  final TextEditingController _filter = new TextEditingController();
  String _searchText = "";

  categoriesModel? categoriesModel_;

  FeedScreenList({this.categoriesModel_});

  getPreferenceData() async {
    prefs = await SharedPreferences.getInstance();
  }

  @override
  void initState() {
    super.initState();
    getPreferenceData();
    _netUtil.isConnected().then((internet) {
      if (internet) {
        // set state while we fetch data from API
        setState(() {
          // calling API to show the data
          //getAllpost();
          detailItems = getFeedDetail(page);

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

    _sc.addListener(() {
      print("scroll listner");
      if (_sc.position.pixels == _sc.position.maxScrollExtent) {


        if (_hasMore && !isSearchClick) {

          Future<detailListModel> data = getFeedDetail(page);
        }
      }
    });
  }

  Future<detailListModel> getFeedDetail(int pageindex) async {
    if (prefs.getInt("feedpostafter") == null) {
      page = 1;
    } else {
      page = await prefs.getInt("feedpostafter")!;
    }

    if (!isLoadingLazy && pageindex > 1) {
      setState(() {
        isLoadingLazy = true;
      });
    }

    NetworkUtil.getFeedList =
        "api/posts-after/post-" + page.toString() + "/" + pageCount.toString();
    //NetworkUtil.getCategoriesdetail = "api/category/8/posts/" +  pageindex.toString() + "/" + pageCount.toString();
    return _netUtil.get(NetworkUtil.getFeedList, true).then((dynamic res) {
      //json.decode used to decode response.body(string to map)
      //print(res['posts'].toString());
    // print("FeedRes = "+NetworkUtil.getFeedList+' Res = '+res.toString());

      if (res != null && res["MessageType"] == 1) {
        // setState(() {
        //   isLoadingLazy = false;
        //   //detailItems = futureGroup.future.then((value) =>  detailListModel.fromJson(value));
        //   page++;
        //   if(res['posts'].isEmpty){
        //     _hasMore = false;
        //   }
        //
        // });

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

    setState(() {
      isLoadingLazy = false;
      //detailItems = futureGroup.future.then((value) =>  detailListModel.fromJson(value));

      print("data length : " + parsedJson.length.toString());
      if (parsedJson.length > 0) {
        totalfeedcount = totalfeedcount + parsedJson.length;

        print("totalfeedcount : " + totalfeedcount.toString());

        if(totalfeedcount < 55){
          if (parsedJson.length < 10) {
            prefs.setInt("feedpostafter", detailItemsListView![0].id!);
            page = detailItemsListView![0].id!;
            _hasMore = false;
          } else {
            //print("id  : " + detailItemsListView![0].id!.toString());
            prefs.setInt("feedpostafter", detailItemsListView![0].id!);
            page = detailItemsListView![0].id!;
          }
        }else{
          _hasMore = false;
        }
      } else {
        _hasMore = false;
      }

      //page = detailItemsListView![detailItemsListView!.length - 1].id!;

      temppagedata = detailItemsListView;
    });

    //return detailList;
  }

  onItemChanged(String value) {
    setState(() {
      openLastindex = -1;
      for (var i = 0; i < detailItemsListView!.length; i++) {
        detailItemsListView![i].isExpanded = false;
      }

      //print("search test : " + value);
      detailItemsListView = filtereddata!
          .where((i) =>
              (i.title.toString().toLowerCase().contains(value.toLowerCase()) ||
                  i.description
                      .toString()
                      .toLowerCase()
                      .contains(value.toLowerCase())))
          .toList();
    });
  }

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
                            title: Text("Feed",
                                style: const TextStyle(
                                    color: Color(0xff000000),
                                    fontWeight: FontWeight.bold)),
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
                          body: RefreshIndicator(
                            key: _refreshIndicatorKey,
                            onRefresh: _refresh,
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
                                          // print("snapshot done" +
                                          //     detailItemsListView!.length
                                          //         .toString());
                                          //print("snapshot data" + snapshot.data!.detaildataList![1].id.toString());

                                          if (snapshot.hasData) {
                                            // hasdata same as data!=null
                                            if (detailItemsListView! != null) {
                                              if (detailItemsListView!.length >
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
                                                    if (openLastindex == -1) {
                                                      //setState(() {
                                                      detailItemsListView![0]
                                                          .isExpanded = true;
                                                      openLastindex = 0;
                                                      //});
                                                    }
                                                    // if (isLoadingLazy) {
                                                    //   //return _buildProgressIndicator();
                                                    //   if(_hasMore){
                                                    //     return loadingView();
                                                    //   }
                                                    //
                                                    // }
                                                    //else {
                                                    return Padding(
                                                      padding:
                                                          EdgeInsets.fromLTRB(
                                                              0, 0, 0, 0),
                                                      child: ExpansionPanelList(
                                                        key: itemKey,
                                                        expansionCallback: (int
                                                                index,
                                                            bool isExpanded) {
                                                          _sc.animateTo(
                                                              _height * index,
                                                              duration: Duration(
                                                                  milliseconds:
                                                                      500),
                                                              curve: Curves
                                                                  .fastOutSlowIn);
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
                                                                      .isExpanded =
                                                                  !detailItemsListView![
                                                                          index]
                                                                      .isExpanded!;
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
                                                            }
                                                            openLastindex =
                                                                index;
                                                          });
                                                        },
                                                        children:
                                                            detailItemsListView!
                                                                .map(
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
                                                                  title: Text(
                                                                item.title!,
                                                                textAlign:
                                                                    TextAlign
                                                                        .left,
                                                                style:
                                                                    TextStyle(
                                                                  fontSize:
                                                                      16.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ));
                                                            },
                                                            isExpanded: item
                                                                .isExpanded!,
                                                            body: Padding(
                                                              //EdgeInsets.all(10),
                                                              padding:
                                                                  EdgeInsets
                                                                      .fromLTRB(
                                                                          0,
                                                                          0,
                                                                          0,
                                                                          0),
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
                                                                  // Padding(
                                                                  // padding: EdgeInsets.all(5.0),
                                                                  //     child: Text(item.description!,
                                                                  //       style: TextStyle(fontSize: 16.0),
                                                                  //     ),
                                                                  // ),
                                                                  Container(
                                                                    alignment:
                                                                        Alignment
                                                                            .center,
                                                                    child:
                                                                        CachedNetworkImage(
                                                                      placeholder:
                                                                          (context, url) =>
                                                                              CircularProgressIndicator(),
                                                                      imageUrl:
                                                                          item.photo!,
                                                                      httpHeaders:
                                                                          headers,
                                                                    ),
                                                                    //child : Image.asset('assets/one.jpg'),
                                                                    //margin: EdgeInsets.all(10),
                                                                    //),
                                                                  ),
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
                                                return noDataView(
                                                    "No Record found");
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
                                    return noDataView("Something went wrong");
                                  }),
                            ),
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
                            child: Text("Feed",
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

    return _netUtil.isConnected().then((internet) {
      if (internet) {
        // set state while we fetch data from API
        setState(() {
          // calling API to show the data
          // you can also do it with any button click.
          page = 0;
          openLastindex = -1;
          detailItemsListView!.clear();
          detailItems = getFeedDetail(page);
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

  shareApp(BuildContext context) async {
    final RenderBox box = context.findRenderObject() as RenderBox;

    await Share.share(
        'hey! check out this new app android : https://play.google.com/store/apps/details?id=com.children.cfe&hl=en  ios : https://apps.apple.com/us/app/children-for-environment/id1609925887',
        subject: 'Children For Environment',
        sharePositionOrigin: box.globalToLocal(Offset.zero) & box.size);
  }
}
