import 'package:audioplayers/audioplayers.dart';

class AudioService {

  AudioService._();

  static final AudioService _instance = AudioService._();

  factory AudioService() {
    return _instance;
  }

  void playSound(AssetSource assetSource) async{
   await  AudioPlayer().play(assetSource, mode: PlayerMode.lowLatency); // faster play low latency eg for a game...
  }
}