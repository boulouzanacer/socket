import 'PostData_Product.dart';
/// CB : "75475756347675"
/// COUNT : "3"
/// RST : "1"
/// PRODUCT : [{"NOM":"SUPERETTE DDSDSD1","PRX":"100","HAS_PRM":"0","PRM":"","DATE_MAJ":"10/10/2023","REGION":"MOHAMMADIA - ALGER"},{"NOM":"SUPERETTE DDSDSD2","PRX":"200","HAS_PRM":"0","PRM":"","DATE_MAJ":"10/10/2023","REGION":"MOHAMMADIA - ALGER"},{"NOM":"SUPERETTE DDSDSD3","PRX":"300","HAS_PRM":"1","PRM":"150","DATE_MAJ":"10/10/2023","REGION":"MOHAMMADIA - ALGER"}]

class PostDataAllResult {


  String? CB;
  String? COUNT;
  String? RST;
  List<PostData_Product>? PRODUCT;

  PostDataAllResult({
      String? CB,
      String? COUNT,
      String? RST,
      List<PostData_Product>? PRODUCT,}){
    CB = CB;
    COUNT = COUNT;
    RST = RST;
    PRODUCT = PRODUCT;
}

  PostDataAllResult.fromJson(dynamic json) {
    CB = json['CB'];
    COUNT = json['COUNT'];
    RST = json['RST'];
    if (json['PRODUCT'] != null) {
      PRODUCT = [];
      json['PRODUCT'].forEach((v) { PRODUCT?.add(PostData_Product.fromJson(v)); });
    }
  }


  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['CB'] = CB;
    data['COUNT'] = COUNT;
    data['RST'] = RST;
    if (PRODUCT != null) {
      data['PRODUCT'] = PRODUCT?.map((v) => v.toJson()).toList();
    }
    return data;
  }

}

