// lib/services/connectivity_service.dart
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  
  Stream<ConnectivityResult> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;
  
  Future<bool> hasConnection() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
  
  Future<SpeedTestResult> checkInternetSpeed() async {
    try {
      final stopwatch = Stopwatch()..start();
      
      // تنزيل ملف صغير (100 KB) لقياس السرعة
      final response = await Dio().get(
        'https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png',
        options: Options(responseType: ResponseType.bytes),
      );
      
      stopwatch.stop();
      
      final bytes = response.data.length;
      final seconds = stopwatch.elapsedMilliseconds / 1000;
      final speedMbps = (bytes * 8) / (seconds * 1000000);
      
      return SpeedTestResult(
        downloadSpeed: speedMbps,
        latency: stopwatch.elapsedMilliseconds,
      );
      
    } catch (e) {
      return SpeedTestResult(downloadSpeed: 0, latency: 9999);
    }
  }
}

class SpeedTestResult {
  final double downloadSpeed; // Mbps
  final int latency; // ms
  
  SpeedTestResult({
    required this.downloadSpeed,
    required this.latency,
  });
  
  String get quality {
    if (downloadSpeed >= 3 && latency < 100) return 'ممتازة';
    if (downloadSpeed >= 1.5 && latency < 200) return 'جيدة';
    if (downloadSpeed >= 0.5 && latency < 500) return 'ضعيفة';
    return 'سيئة جداً';
  }
}
