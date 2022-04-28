class ExpansionpanelItem {

  //List<ExpansionpanelItem>? categoriesList;

  bool? isExpanded;
  int? id;
  int? is_favorite;
  String? title;
  String? description;
  String? photo;
  String? video_code;
  String? createdAt;
  String? updatedAt;
  //Icon? leading;

  ExpansionpanelItem({this.id,this.is_favorite, this.title, this.description, this.photo,this.video_code,this.createdAt,
    this.updatedAt});

  ExpansionpanelItem.fromJson(Map<String, dynamic> json) {
    isExpanded = false;
    id = json['id'];
    is_favorite = json['is_favorite'];
    title = json['title'];
    description = json['description'];
    photo = json['photo'];
    video_code = json['video_code'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['isExpanded'] = this.isExpanded;
    data['id'] = this.id;
    data['is_favorite'] = this.is_favorite;
    data['title'] = this.title;
    data['description'] = this.description;
    data['photo'] = this.photo;
    data['video_code'] = this.video_code;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }

}