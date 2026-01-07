import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:map_launcher/map_launcher.dart';

class IntentUtils {
  IntentUtils._();

  static Future<void> openMapsSheet(context, double lat, double log) async {

    final double destinationLatitude= lat;
    final double destinationLongitude = log;

    try {
      final availableMaps = await MapLauncher.installedMaps;
      showModalBottomSheet(
        context: context,
        isDismissible: true,
        builder: (BuildContext context) {
          return SafeArea(
            child: SingleChildScrollView(
              child: Container(
                child: Wrap(
                  children: <Widget>[
                    for (var map in availableMaps)
                      ListTile(
                        onTap:  (){
                          map.showDirections(destination :  Coords(destinationLatitude, destinationLongitude));
                          Navigator.of(context).pop(true);
                        },
                        title: Text(map.mapName),
                        leading: SvgPicture.asset(
                          map.icon,
                          height: 30.0,
                          width: 30.0,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      print(e);
    }
  }
}