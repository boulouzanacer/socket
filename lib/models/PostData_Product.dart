import 'package:easy_localization/easy_localization.dart';

/// NOM : "SUPERETTE DDSDSD1"
/// PRX : "100"
/// HAS_PRM : "0"
/// PRM : ""
/// DATE_MAJ : "10/10/2023"
/// REGION : "MOHAMMADIA - ALGER"

class PostData_Product {

  String NOM;
  String PRD;
  double PRX;
  String HAS_PRM;
  double PRM;
  DateTime DATE_MAJ;
  String REGION;
  double LA;
  double LO;
  bool IS_THE_BEST = false;

  PostData_Product({
    required this.NOM,
    required this.PRD,
    required this.PRX,
    required this.HAS_PRM,
    required this.PRM,
    required this.DATE_MAJ,
    required this.REGION,
    required this.LA,
    required this.LO,
    required this.IS_THE_BEST});

  factory PostData_Product.fromJson(Map<String, dynamic> json) {
    DateFormat format = DateFormat("dd/MM/yyyy");

    return PostData_Product(
      NOM: json['NOM'],
      PRD: json['PRD'],
      PRX: double.parse(json['PRX']),
      HAS_PRM: json['HAS_PRM'],
      PRM: double.parse(json['PRM']),
      DATE_MAJ: format.parse(json['DATE_MAJ']),
      REGION: json['REGION'],
      LA: double.parse(json['LA']),
      LO: double.parse(json['LO']),
      IS_THE_BEST: false,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['NOM'] = NOM;
    data['PRD'] = PRD;
    data['PRX'] = PRX;
    data['HAS_PRM'] = HAS_PRM;
    data['PRM'] = PRM;
    data['DATE_MAJ'] = DATE_MAJ;
    data['REGION'] = REGION;
    return data;
  }
}