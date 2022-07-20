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
import 'dart:io' show Platform;

class FavoritesList extends StatefulWidget {
  FavoritesList({Key? key}) : super(key: key);

  @override
  FavoritesListScreen createState() => FavoritesListScreen();
}

class FavoritesListScreen extends State<FavoritesList> {
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
  List<ExpansionpanelItem>? detailItemsListView = <ExpansionpanelItem>[];
  List<ExpansionpanelItem>? filtereddata = <ExpansionpanelItem>[];
  List<ExpansionpanelItem>? temppagedata = <ExpansionpanelItem>[];

  Future<detailListModel>? detailItems;

  Icon actionIcon = new Icon(Icons.search);
  final TextEditingController _filter = new TextEditingController();
  String _searchText = "";

  categoriesModel? categoriesModel_;

  FavoritesListScreen({this.categoriesModel_});

  @override
  void initState() {
    super.initState();
    _netUtil.isConnected().then((internet) {
      if (internet) {
        // set state while we fetch data from API
        setState(() {
          // calling API to show the data
          //getAllpost();
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

    _sc.addListener(() {
      if (_sc.position.pixels == _sc.position.maxScrollExtent) {
        //print("lazy load listener called");

        if (_hasMore && !isSearchClick) {
          //print("lazy load called");
          Future<detailListModel> data = getcategoriesDetail(page);
        }

      }
    });
  }

  Future<detailListModel> getcategoriesDetail(int pageindex) async {
    if (!isLoadingLazy && pageindex > 0) {
      setState(() {
        isLoadingLazy = true;
      });
    }

    NetworkUtil.getFavoriteList =
        "api/favorites/" + pageindex.toString() + "/" + pageCount.toString();
    return _netUtil.get(NetworkUtil.getFavoriteList, true).then((dynamic res) {
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

      //print("data length : " + parsedJson.length.toString());
      if (parsedJson.length < 10) {
        _hasMore = false;
      } else {
        page = detailItemsListView!.length;
      }

      temppagedata = detailItemsListView;
    });
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
                            title: Text("Favorites",
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
                                          //print("snapshot done" + detailItemsListView!.length.toString());
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
                                                                  Align(
                                                                    alignment:
                                                                        Alignment
                                                                            .topRight,
                                                                    child:
                                                                        Padding(
                                                                      padding: EdgeInsets
                                                                          .fromLTRB(
                                                                              0,
                                                                              0,
                                                                              15,
                                                                              0),
                                                                      child:
                                                                          IconButton(
                                                                        icon: Icon(
                                                                            Customicons
                                                                                .heart,
                                                                            color:
                                                                                Color(0xffFF621C)),
                                                                        onPressed:
                                                                            () {
                                                                          AddRemoveFavorite(
                                                                              item.id);
                                                                        },
                                                                      ),
                                                                    ),
                                                                  ),
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
                                                    "Nothing is added to favorites yet");
                                              }
                                            } else {
                                              // display error message if your list or data is null.
                                              return noDataView(
                                                  "Nothing is added to favorites yet");
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

    return _netUtil.isConnected().then((internet) {
      if (internet) {
        // set state while we fetch data from API
        setState(() {
          // calling API to show the data
          // you can also do it with any button click.
          page = 0;
          openLastindex = -1;
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

  AddRemoveFavorite(int? id) {
    NetworkUtil.RemoveFromFavorite = "api/unbookmark/" + id.toString();
    return _netUtil
        .get(NetworkUtil.RemoveFromFavorite, true)
        .then((dynamic res) {
      if (res != null && res["MessageType"] == 1) {
        Fluttertoast.showToast(
            msg: res["Message"],
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.SNACKBAR,
            timeInSecForIosWeb: 1,
            backgroundColor: Color(0xff69F0AE),
            textColor: Color(0xff19442C),
            fontSize: 16.0);

        _refresh();
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

  shareApp(BuildContext context) async {
    final RenderBox box = context.findRenderObject() as RenderBox;

    await Share.share(
        'hey! check out this new app android : https://play.google.com/store/apps/details?id=com.children.cfe&hl=en  ios : https://apps.apple.com/app/cfe-children-for-environment/id1609925887',
        subject: 'Children For Environment',
        sharePositionOrigin: box.globalToLocal(Offset.zero) & box.size);
  }
}
