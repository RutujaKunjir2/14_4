import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:CFE/Networking/networkUtil.dart';
import '../models/CustomAlertDialog.dart';
import 'Dashboard_screen.dart';
import 'dart:convert';
import 'consumable_store.dart';
import 'PaymentHistory.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(IosPayment());
}

const bool _kAutoConsume = true;

// Old In App Submission one with version 1.0.12
// const String halfYearPlan = 'HalfYearlyCFESubscription';
// const String yearlyPlan = 'YearlyCFESubscription';

// New In App Submission with new version 1.0.13
const String halfYearPlan = 'Half_Yearly_Plan';
const String yearlyPlan = 'Yearly_Plan';

const List<String> _kProductIds = <String>[
  halfYearPlan,
  yearlyPlan
];

class IosPayment extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<IosPayment> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  List<String> _notFoundIds = [];
  List<ProductDetails> _products = [];
  List<PurchaseDetails> _purchases = [];
  List<String> _consumables = [];
  bool _isAvailable = false;
  bool _purchasePending = false;
  bool _loading = true;
  String? _queryProductError;
  NetworkUtil _netUtil = new NetworkUtil();
  late SharedPreferences prefs;

  @override
  void initState()
  {
    getPreferenceData();

    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList)
    {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      _subscription.resume();
    });
    initStoreInfo();
    super.initState();
  }

  getPreferenceData() async {
    prefs = await SharedPreferences.getInstance();
  }


  Future<void> initStoreInfo() async {
    final bool isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      setState(() {
        _isAvailable = isAvailable;
        _products = [];
        _purchases = [];
        _notFoundIds = [];
        _consumables = [];
        _purchasePending = false;
        _loading = false;
      });
      return;
    }

    if (Platform.isIOS) {
      var iosPlatformAddition = _inAppPurchase
          .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iosPlatformAddition.setDelegate(ExamplePaymentQueueDelegate());
    }

    ProductDetailsResponse productDetailResponse =
    await _inAppPurchase.queryProductDetails(_kProductIds.toSet());
    if (productDetailResponse.error != null) {
      setState(() {
        _queryProductError = productDetailResponse.error!.message;
        _isAvailable = isAvailable;
        _products = productDetailResponse.productDetails;
        _purchases = [];
        _notFoundIds = productDetailResponse.notFoundIDs;
        _consumables = [];
        _purchasePending = false;
        _loading = false;
      });
      return;
    }

    if (productDetailResponse.productDetails.isEmpty) {
      setState(() {
        _queryProductError = null;
        _isAvailable = isAvailable;
        _products = productDetailResponse.productDetails;
        _purchases = [];
        _notFoundIds = productDetailResponse.notFoundIDs;
        _consumables = [];
        _purchasePending = false;
        _loading = false;
      });
      return;
    }

    List<String> consumables = await ConsumableStore.load();
    setState(() {
      _isAvailable = isAvailable;
      _products = productDetailResponse.productDetails;
      _notFoundIds = productDetailResponse.notFoundIDs;
      _consumables = consumables;
      _purchasePending = false;
      _loading = false;
    });
  }

  @override
  void dispose() {
    if (Platform.isIOS) {
      var iosPlatformAddition = _inAppPurchase
          .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      iosPlatformAddition.setDelegate(null);
    }
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> stack = [];
    if (_queryProductError == null) {
      stack.add(
        ListView(
          children: [
            _buildConnectionCheckTile(),
            Container(
              width: 208,
              height: 228,
              alignment: Alignment.center,
              //padding: EdgeInsets.all(10),
              padding: EdgeInsets.fromLTRB(10, 10, 10, 5),
              child: Image(image: AssetImage('assets/kid-money.png')),
            ),
            _buildProductList(),
            //_buildConsumableBox(),
            _buildRestoreButton(),
          ],
        ),
      );
    } else {
      stack.add(Center(
        child: Text(_queryProductError!),
      ));
    }
    if (_purchasePending) {
      stack.add(
        Stack(
          children: const [
            Opacity(
              opacity: 0.3,
              child: ModalBarrier(dismissible: false, color: Colors.grey),
            ),
            Center(
              child: CircularProgressIndicator(),
            ),
          ],
        ),
      );
    }

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          leading: IconButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) => const Dashboard(),
                ),
                    (route) => false,
              );
            },
            icon: Icon(Icons.arrow_back),
          ),
          backgroundColor: Color(0xffFCD800),
          title: Text("Payment",
              style: const TextStyle(
                  color: Color(0xff000000), fontWeight: FontWeight.bold)),
          iconTheme: IconThemeData(color: Colors.black),
          actions: <Widget>[
            Visibility(
              child: Padding(
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
                  )
              ),
              visible: true,
            )
          ],
        ),
        body: Stack(
          children: stack,
        ),
      ),
    );
  }

  Card _buildConnectionCheckTile() {
    if (_loading) {
      return const Card(child: ListTile(title: Text('Trying to connect...')));
    }
    final Widget storeHeader = ListTile(
      leading: Icon(_isAvailable ? Icons.check : Icons.block,
          color: _isAvailable ? Colors.green : ThemeData.light().errorColor),
      title: Text(
          'The payment is ' + (_isAvailable ? 'available' : 'unavailable') + '.'),
    );
    final List<Widget> children = <Widget>[storeHeader];

    if (!_isAvailable) {
      children.addAll([
        const Divider(),
        ListTile(
          title: Text('Not connected',
              style: TextStyle(color: ThemeData
                  .light()
                  .errorColor)),
          subtitle: const Text(
              'Unable to connect to the payments processor. Has this app been configured correctly? See the example README for instructions.'),
        ),
      ]);
    }
    return Card(child: Column(children: children));
  }

  Card _buildProductList() {
    if (_loading) {
      return const Card(
          child: (ListTile(
              leading: CircularProgressIndicator(),
              title: Text('Fetching plans...'))));
    }
    if (!_isAvailable) {
      return const Card();
    }
    const ListTile productHeader = ListTile(title: Text('Select Subscription Plan'));
    List<ListTile> productList = <ListTile>[];
    if (_notFoundIds.isNotEmpty) {
      productList.add(ListTile(
          title: Text('[${_notFoundIds.join(", ")}] not found',
              style: TextStyle(color: ThemeData.light().errorColor)),
          subtitle: const Text(
              'This app needs special configuration to run. Please see example/README.md for instructions.')));
    }

    // This loading previous purchases code is just a demo. Please do not use this as it is.
    // In your app you should always verify the purchase data using the `verificationData` inside the [PurchaseDetails] object before trusting it.
    // We recommend that you use your own server to verify the purchase data.
    Map<String, PurchaseDetails> purchases =
    Map.fromEntries(_purchases.map((PurchaseDetails purchase) {
      if (purchase.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchase);
      }
      return MapEntry<String, PurchaseDetails>(purchase.productID, purchase);
    }));
    productList.addAll(_products.map(
          (ProductDetails productDetails) {
        PurchaseDetails? previousPurchase = purchases[productDetails.id];
        return ListTile(
            title: Text(
              productDetails.title,
            ),
            subtitle: Text(
              productDetails.description,
            ),
            trailing: previousPurchase != null
                ? IconButton(
                onPressed: () => confirmPriceChange(context),
                icon: const Icon(Icons.upgrade))
                : TextButton(
              child: Text(productDetails.price),
              style: TextButton.styleFrom(
                backgroundColor: Colors.green[800],
                primary: Colors.white,
              ),
              onPressed: () async {
                late PurchaseParam purchaseParam;

                if (Platform.isAndroid) {
                  // NOTE: If you are making a subscription purchase/upgrade/downgrade, we recommend you to
                  // verify the latest status of you your subscription by using server side receipt validation
                  // and update the UI accordingly. The subscription purchase status shown
                  // inside the app may not be accurate.
                  final oldSubscription =
                  _getOldSubscription(productDetails, purchases);

                  purchaseParam = GooglePlayPurchaseParam(
                      productDetails: productDetails,
                      applicationUserName: null,
                      changeSubscriptionParam: (oldSubscription != null)
                          ? ChangeSubscriptionParam(
                        oldPurchaseDetails: oldSubscription,
                        prorationMode: ProrationMode
                            .immediateWithTimeProration,
                      )
                          : null);
                } else {
                  purchaseParam = PurchaseParam(
                    productDetails: productDetails,
                    applicationUserName: null,
                  );
                }

                var transactions = await SKPaymentQueueWrapper().transactions();
                transactions.forEach((skPaymentTransactionWrapper) {
                  SKPaymentQueueWrapper().finishTransaction(skPaymentTransactionWrapper);
                });
                if ((productDetails.id == halfYearPlan) || (productDetails.id == yearlyPlan)) {
                  _inAppPurchase.buyConsumable(
                      purchaseParam: purchaseParam,
                      autoConsume: _kAutoConsume || Platform.isIOS);
                } else {
                  _inAppPurchase.buyNonConsumable(
                      purchaseParam: purchaseParam);
                }
              },
            ));
      },
    ));

    return Card(
        child: Column(
            children: <Widget>[productHeader, const Divider()] + productList));
  }

  Card _buildConsumableBox() {
    if (_loading) {
      return const Card(
          child: (ListTile(
              leading: CircularProgressIndicator(),
              title: Text('Fetching consumables...'))));
    }
    if (!_isAvailable || _notFoundIds.contains(halfYearPlan)) {
      return const Card();
    }
    const ListTile consumableHeader =
    ListTile(title: Text('Purchased consumables'));
    final List<Widget> tokens = _consumables.map((String id) {
      return GridTile(
        child: IconButton(
          icon: const Icon(
            Icons.stars,
            size: 42.0,
            color: Colors.orange,
          ),
          splashColor: Colors.yellowAccent,
          onPressed: () => consume(id),
        ),
      );
    }).toList();
    return Card(
        child: Column(children: <Widget>[
          consumableHeader,
          const Divider(),
          GridView.count(
            crossAxisCount: 5,
            children: tokens,
            shrinkWrap: true,
            padding: const EdgeInsets.all(16.0),
          )
        ]));
  }

  Widget _buildRestoreButton() {
    if (_loading) {
      return Container();
    }

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            child: const Text('Restore Purchase'),
            style: TextButton.styleFrom(
              backgroundColor: Colors.green[400],
              primary: Colors.white,
            ),
            onPressed: ()
            {
              _inAppPurchase.restorePurchases();

              showDialog(
                barrierColor: Colors.black26,
                context: context,
                builder: (context) {
                  return CustomAlertDialog(
                    title: "Alert",
                    description: "Previous purchase is restored.",
                    okbtn: true,
                    cancelbtn: false,
                  );
                },
              );

            },
          ),
        ],
      ),
    );
  }

  Future<void> consume(String id) async {
    await ConsumableStore.consume(id);
    final List<String> consumables = await ConsumableStore.load();
    setState(() {
      _consumables = consumables;
    });
  }

  void showPendingUI() {
    setState(() {
      _purchasePending = true;
    });
  }

  void deliverProduct(PurchaseDetails purchaseDetails) async {
    // IMPORTANT!! Always verify purchase details before delivering the product.
    if ((purchaseDetails.productID == halfYearPlan) ||
        (purchaseDetails.productID == yearlyPlan)) {
      await ConsumableStore.save(purchaseDetails.purchaseID!);
      List<String> consumables = await ConsumableStore.load();
      setState(() {
        _purchasePending = false;
        _consumables = consumables;
      });
    } else {
      setState(() {
        _purchases.add(purchaseDetails);
        _purchasePending = false;
      });
    }
  }

  void handleError(IAPError error) {
    setState(() {
      _purchasePending = false;
    });
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // IMPORTANT!! Always verify a purchase before delivering the product.
    // For the purpose of an example, we directly return true.
    Map bodyRes = {
      "serverVerification":
      purchaseDetails.verificationData.serverVerificationData,
      "localVerification":
      purchaseDetails.verificationData.localVerificationData,
      "productID": purchaseDetails.productID,
      "purchaseID": purchaseDetails.purchaseID,
    };

    var res = await iapService(purchaseDetails);

    if (res) {
      return Future<bool>.value(true);
    }
    else {
      return Future<bool>.value(false);
    }
  }

  void _handleInvalidPurchase(PurchaseDetails purchaseDetails) {
    // handle invalid purchase here if  _verifyPurchase` failed.
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
     //print("WelcomeBack = "+purchaseDetails.status.toString());
      if (purchaseDetails.status == PurchaseStatus.pending) {
        showPendingUI();
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          handleError(purchaseDetails.error!);
        }
        else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored)
        {
          bool valid = await _verifyPurchase(purchaseDetails);
          if (valid) {
            deliverProduct(purchaseDetails);
          } else {
            _handleInvalidPurchase(purchaseDetails);
            return;
          }
        }
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    });
  }

  Future<void> confirmPriceChange(BuildContext context) async {
    if (Platform.isAndroid) {
      final InAppPurchaseAndroidPlatformAddition androidAddition =
      _inAppPurchase
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      var priceChangeConfirmationResult =
      await androidAddition.launchPriceChangeConfirmationFlow(
        sku: 'purchaseId',
      );
      if (priceChangeConfirmationResult.responseCode == BillingResponse.ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Price change accepted'),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            priceChangeConfirmationResult.debugMessage ??
                "Price change failed with code ${priceChangeConfirmationResult.responseCode}",
          ),
        ));
      }
    }
    if (Platform.isIOS) {
      var iapStoreKitPlatformAddition = _inAppPurchase
          .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iapStoreKitPlatformAddition.showPriceConsentIfNeeded();
    }
  }

  GooglePlayPurchaseDetails? _getOldSubscription(
      ProductDetails productDetails, Map<String, PurchaseDetails> purchases) {
    // This is just to demonstrate a subscription upgrade or downgrade.
    // This method assumes that you have only 2 subscriptions under a group, 'subscription_silver' & 'subscription_gold'.
    // The 'subscription_silver' subscription can be upgraded to 'subscription_gold' and
    // the 'subscription_gold' subscription can be downgraded to 'subscription_silver'.
    // Please remember to replace the logic of finding the old subscription Id as per your app.
    // The old subscription is only required on Android since Apple handles this internally
    // by using the subscription group feature in iTunesConnect.
    GooglePlayPurchaseDetails? oldSubscription;
    // if (productDetails.id == basePlan180 &&
    //     purchases[_kGoldSubscriptionId] != null) {
    //   oldSubscription =
    //       purchases[_kGoldSubscriptionId] as GooglePlayPurchaseDetails;
    // } else if (productDetails.id == _kGoldSubscriptionId &&
    //     purchases[basePlan180] != null) {
    //   oldSubscription = purchases[basePlan180] as GooglePlayPurchaseDetails;
    // }
    return oldSubscription;
  }

  Future<bool> iapService(PurchaseDetails purchaseDetails) async
  {
    if (purchaseDetails.status == PurchaseStatus.purchased)
    {
      var amountSub = "0";
      for(final prod in _products){
        if (prod.id == purchaseDetails.productID){
          amountSub = prod.price;
        }
      }

      var body = {
        "receipt_data" : purchaseDetails.verificationData.serverVerificationData,
        "is_renewable" : "1",
        "amount" : ""+amountSub,
        "device_id" : ""+NetworkUtil.deviceId,
      };

      prefs.setString('IAP_receipt', ""+purchaseDetails.verificationData.serverVerificationData);
      prefs.setString('IAP_amount', ""+amountSub);

     //print("receipt_data : " + body.toString());

      _netUtil.post(NetworkUtil.verifyReceipt,body,false).then((dynamic res)
      {
        //print("VerifyReceipt : " + res.toString());

        if ((res != null && res["MessageType"] == 1))
        {
          if(_purchasePending){
            NetworkUtil.token = res["token"];
            NetworkUtil.secret = res["secret"];
            NetworkUtil.isLogin = true;
            NetworkUtil.isSocialLogin = false;

            if (res["SubscriptionEndDate"] != null) {
              NetworkUtil.subscription_end_date = res["SubscriptionEndDate"];
            }

            if (res["subscribed"] == 0) {
              NetworkUtil.isSubScribedUser = false;
            } else {
              NetworkUtil.isSubScribedUser = true;
            }

            prefs.setString('token', res["token"]);
            prefs.setString('secret', res["secret"]);
            prefs.setBool('isSocialLogin', false);
            prefs.setBool('isLogin', true);

            Fluttertoast.showToast(
                msg: 'Your purchase was stored successfully',
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.SNACKBAR,
                timeInSecForIosWeb: 1,
                backgroundColor: Color(0xff69F0AE),
                textColor: Color(0xff19442C),
                fontSize: 16.0);

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) => const Dashboard(),
              ),
                  (route) => false,
            );
            return Future<bool>.value(true);
          }
          else
          {
            NetworkUtil.token = res["token"];
            NetworkUtil.secret = res["secret"];
            prefs.setString('token', res["token"]);
            prefs.setString('secret', res["secret"]);
            return Future<bool>.value(false);
          }

        }
        else if ((res != null && res["MessageType"] == 0))
        {
          NetworkUtil.token = res["token"];
          NetworkUtil.secret = res["secret"];
          prefs.setString('token', res["token"]);
          prefs.setString('secret', res["secret"]);
          return Future<bool>.value(false);
        }
        else {
         /* Fluttertoast.showToast(
              msg: 'Transaction failed.Please try again!',
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.SNACKBAR,
              timeInSecForIosWeb: 1,
              backgroundColor: Color(0xffE74C3C),
              textColor: Colors.white,
              fontSize: 16.0);*/

          return Future<bool>.value(false);
        }

      }).catchError((e)
      {
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
    return Future<bool>.value(false);
  }

}

/// Example implementation of the
/// [`SKPaymentQueueDelegate`](https://developer.apple.com/documentation/storekit/skpaymentqueuedelegate?language=objc).
///
/// The payment queue delegate can be implementated to provide information
/// needed to complete transactions.
class ExamplePaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
      SKPaymentTransactionWrapper transaction, SKStorefrontWrapper storefront) {
    return true;
  }

  @override
  bool shouldShowPriceConsent() {
    return false;
  }
}