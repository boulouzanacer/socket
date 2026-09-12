import 'package:easy_localization/easy_localization.dart';

/// NOM : "SUPERETTE DDSDSD1"
/// PRX : "100"
/// HAS_PRM : "0"
/// PRM : ""
/// DATE_MAJ : "10/10/2023"
/// REGION : "MOHAMMADIA - ALGER"

double _safeDouble(dynamic value, [double fallback = 0.0]) {
  if (value == null) return fallback;
  String s = value.toString().trim();
  if (s.isEmpty) return fallback;
  s = s.replaceAll(',', '.');
  try {
    return double.parse(s);
  } catch (e) {
    return fallback;
  }
}

DateTime _safeDate(String pattern, dynamic value, DateTime fallback) {
  if (value == null) return fallback;
  String s = value.toString().trim();
  if (s.isEmpty) return fallback;
  try {
    return DateFormat(pattern).parse(s);
  } catch (e) {
    try {
      return DateTime.parse(s);
    } catch (e2) {
      return fallback;
    }
  }
}

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
    final fallbackDate = DateTime.now();

    return PostData_Product(
      NOM: json['NOM']?.toString() ?? '',
      PRD: json['PRD']?.toString() ?? '',
      PRX: _safeDouble(json['PRX']),
      HAS_PRM: json['HAS_PRM']?.toString() ?? '0',
      PRM: _safeDouble(json['PRM']),
      DATE_MAJ: _safeDate("dd/MM/yyyy", json['DATE_MAJ'], fallbackDate),
      REGION: json['REGION']?.toString() ?? '',
      LA: _safeDouble(json['LA']),
      LO: _safeDouble(json['LO']),
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