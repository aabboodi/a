// lib/services/adaptive_streaming_service.dart
class AdaptiveStreamingService {
  final RtcEngine agoraEngine;
  final ConnectivityService connectivity;
  
  NetworkQuality _currentQuality = NetworkQuality.good;
  Timer? _qualityCheckTimer;
  
  AdaptiveStreamingService({
    required this.agoraEngine,
    required this.connectivity,
  });
  
  void initialize() {
    // مراقبة جودة الشبكة
    agoraEngine.registerEventHandler(RtcEngineEventHandler(
      onNetworkQuality: (connection, remoteUid, txQuality, rxQuality) {
        _handleNetworkQuality(txQuality, rxQuality);
      },
      onRtcStats: (connection, stats) {
        _handleRtcStats(stats);
      },
    ));
    
    // فحص دوري للاتصال
    _qualityCheckTimer = Timer.periodic(Duration(seconds: 5), (_) {
      _checkConnectionQuality();
    });
  }
  
  void _handleNetworkQuality(
    QualityType txQuality,
    QualityType rxQuality,
  ) {
    // تحديد الجودة بناءً على أسوأ الحالتين
    final worstQuality = txQuality.index > rxQuality.index 
      ? txQuality 
      : rxQuality;
    
    NetworkQuality newQuality;
    
    switch (worstQuality) {
      case QualityType.qualityExcellent:
      case QualityType.qualityGood:
        newQuality = NetworkQuality.good;
        break;
      case QualityType.qualityPoor:
      case QualityType.qualityBad:
        newQuality = NetworkQuality.poor;
        break;
      case QualityType.qualityVbad:
      case QualityType.qualityDown:
        newQuality = NetworkQuality.veryPoor;
        break;
      default:
        newQuality = NetworkQuality.good;
    }
    
    if (newQuality != _currentQuality) {
      _currentQuality = newQuality;
      _adjustVideoQuality(newQuality);
    }
  }
  
  Future<void> _adjustVideoQuality(NetworkQuality quality) async {
    print('Adjusting video quality to: $quality');
    
    VideoEncoderConfiguration config;
    
    switch (quality) {
      case NetworkQuality.good:
        config = VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 1280, height: 720),
          frameRate: 30,
          bitrate: 2000,
          minBitrate: 1000,
          orientationMode: OrientationMode.orientationModeAdaptive,
        );
        break;
        
      case NetworkQuality.poor:
        config = VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 640, height: 480),
          frameRate: 15,
          bitrate: 800,
          minBitrate: 400,
          orientationMode: OrientationMode.orientationModeAdaptive,
        );
        break;
        
      case NetworkQuality.veryPoor:
        config = VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 320, height: 240),
          frameRate: 10,
          bitrate: 300,
          minBitrate: 150,
          orientationMode: OrientationMode.orientationModeAdaptive,
        );
        break;
    }
    
    await agoraEngine.setVideoEncoderConfiguration(config);
    
    // تفعيل/تعطيل الفيديو في الحالات الصعبة جداً
    if (quality == NetworkQuality.veryPoor) {
      // عرض تحذير للمستخدم
      print('⚠️ Network very poor - consider audio-only mode');
    }
  }
  
  Future<void> _checkConnectionQuality() async {
    final result = await connectivity.checkInternetSpeed();
    
    if (result.downloadSpeed < 0.5) { // أقل من 500 kbps
      _adjustVideoQuality(NetworkQuality.veryPoor);
    } else if (result.downloadSpeed < 1.5) { // أقل من 1.5 mbps
      _adjustVideoQuality(NetworkQuality.poor);
    }
  }
  
  void dispose() {
    _qualityCheckTimer?.cancel();
  }
}

enum NetworkQuality { good, poor, veryPoor }
