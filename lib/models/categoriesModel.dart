class categoriesModel {
  int? id;
  String? categoryName;
  String? parent;
  String? category_cover_image;
  String? createdAt;
  String? updatedAt;

  categoriesModel(
      {this.id,
        this.categoryName,
        this.parent,
        this.category_cover_image,
        this.createdAt,
        this.updatedAt});

  categoriesModel.fromJson(Map<String, dynamic> json) {
    //print("json" + json.toString());
    id = json['id'];
    categoryName = json['category_name'];
    parent = json['parent'];
    category_cover_image = json['category_cover_image'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['category_name'] = this.categoryName;
    data['parent'] = this.parent;
    data['category_cover_image'] = this.category_cover_image;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}
