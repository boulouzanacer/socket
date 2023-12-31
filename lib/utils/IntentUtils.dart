import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

class IntentUtils {
  IntentUtils._();
  static Future<void> launchGoogleMaps() async {
    const double destinationLatitude= 36.7223402;
    const double destinationLongitude = 3.2024328;
    final uri = Uri(
        scheme: "google.navigation",
        // host: '"0,0"',  {here we can put host}
        queryParameters: {
          'q': '$destinationLatitude, $destinationLongitude'
        });
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint('An error occurred');
    }
  }
}