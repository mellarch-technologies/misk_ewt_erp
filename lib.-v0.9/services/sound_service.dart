import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

class SoundService {
  SoundService._();
  static final instance = SoundService._();

  void playClick() => FlutterRingtonePlayer().playNotification();
  void playDelete() => FlutterRingtonePlayer().playAlarm();
  void playSuccess() => FlutterRingtonePlayer().playNotification();
}
