class PostData_Market {
  String CC;
  String NOM;
  String COMUNE;
  String WILAYA;

  PostData_Market({
    required this.CC,
    required this.NOM,
    required this.COMUNE,
    required this.WILAYA});

  factory PostData_Market.fromJson(Map<String, dynamic> json) {
    return PostData_Market(
      CC: json['CC'],
      NOM: json['NOM'],
      COMUNE: json['COMMUNE'],
      WILAYA: json['WILAYA'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['CC'] = CC;
    data['NOM'] = NOM;
    data['COMMUNE'] = COMUNE;
    data['WILAYA'] = WILAYA;
    return data;
  }
}