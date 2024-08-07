import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_audio_recorder_method_channel.dart';

abstract class FlutterAudioRecorderPlatform extends PlatformInterface {
  /// Constructs a FlutterAudioRecorderPlatform.
  FlutterAudioRecorderPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterAudioRecorderPlatform _instance = MethodChannelFlutterAudioRecorder();

  /// The default instance of [FlutterAudioRecorderPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterAudioRecorder].
  static FlutterAudioRecorderPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterAudioRecorderPlatform] when
  /// they register themselves.
  static set instance(FlutterAudioRecorderPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
