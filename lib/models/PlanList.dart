class PlanList {
  int? id;
  String? title;
  String? identifier;
  String? stripeId;
  String? price;
  String? createdAt;
  String? updatedAt;

  PlanList(
      {this.id,
        this.title,
        this.identifier,
        this.stripeId,
        this.price,
        this.createdAt,
        this.updatedAt});

  PlanList.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    identifier = json['identifier'];
    stripeId = json['stripe_id'];
    price = json['price'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['title'] = this.title;
    data['identifier'] = this.identifier;
    data['stripe_id'] = this.stripeId;
    data['price'] = this.price;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}
