

import 'FastFactsData.dart';

class fastFactsModel{
  List<FastFactsData>? detaildataList;

  fastFactsModel({this.detaildataList});

  fastFactsModel.fromJson(List<dynamic> parsedJson){
    detaildataList= <FastFactsData>[];
    parsedJson.forEach((v){
      //print("foreach data " + v);
      detaildataList?.add(FastFactsData.fromJson(v));
    });
  }
}