import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

class DeviceHelper {

  static Future<Map<String, dynamic>> deviceData() async {

    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final AndroidDeviceInfo info = await deviceInfo.androidInfo;

      return {
        'platform': 'android',
        'model': info.model,
        'manufacturer': info.manufacturer,
        'version': info.version.release,
        'sdk': info.version.sdkInt,
        'device_id': info.id,
        'is_physical': info.isPhysicalDevice,
      };

    }

    else if (Platform.isIOS) {
      final IosDeviceInfo info = await deviceInfo.iosInfo;

      return {
        'platform': 'ios',
        'name': info.name,
        'system': info.systemName,
        'version': info.systemVersion,
        'model': info.model,
        'device_id': info.identifierForVendor,
        'is_physical': info.isPhysicalDevice,
      };
    }

    return {'platform': 'unknown'};
  }

}
