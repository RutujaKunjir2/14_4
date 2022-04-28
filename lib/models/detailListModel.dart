import 'package:CFE/screen/categoryContent.dart';

import 'ExpansionpanelItem.dart';

class detailListModel{
  List<ExpansionpanelItem>? detaildataList;

  detailListModel({this.detaildataList});

  detailListModel.fromJson(List<dynamic> parsedJson){
    detaildataList= <ExpansionpanelItem>[];
    parsedJson.forEach((v){
      //print("foreach data " + v);
      detaildataList?.add(ExpansionpanelItem.fromJson(v));
    });
  }
}