import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder_method_channel.dart';

void main() {
  MethodChannelFlutterAudioRecorder platform = MethodChannelFlutterAudioRecorder();
  const MethodChannel channel = MethodChannel('flutter_audio_recorder');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
