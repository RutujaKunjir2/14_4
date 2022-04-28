

import 'package:CFE/models/categoriesModel.dart';

class categoriesListModel{
  List<categoriesModel>? categoriesList;

  categoriesListModel({this.categoriesList});

  categoriesListModel.fromJson(List<dynamic> parsedJson){
    categoriesList=<categoriesModel>[];
    parsedJson.forEach((v){
      categoriesList?.add(categoriesModel.fromJson(v));
    });
  }
}