class FastFactsData {

  int? id;
  String? title;
  String? description;
  String? fact_image;
  String? fact_image_url;
  String? createdAt;
  String? updatedAt;
  //Icon? leading;

  FastFactsData({this.id,this.title, this.description, this.fact_image,this.fact_image_url,this.createdAt,
    this.updatedAt});

  FastFactsData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    description = json['description'];
    fact_image = json['fact_image'];
    fact_image_url = json['fact_image_url'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();

    data['id'] = this.id;
    data['title'] = this.title;
    data['description'] = this.description;
    data['photo'] = this.fact_image;
    data['fact_image_url'] = this.fact_image_url;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }

}