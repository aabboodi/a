// lib/core/providers/app_state.dart
class AppState extends ChangeNotifier {
  User? _currentUser;
  ConnectivityStatus _connectivityStatus = ConnectivityStatus.unknown;
  bool _isSyncing = false;
  List<PendingOperation> _pendingOperations = [];
  
  User? get currentUser => _currentUser;
  ConnectivityStatus get connectivityStatus => _connectivityStatus;
  bool get isSyncing => _isSyncing;
  int get pendingOperationsCount => _pendingOperations.length;
  bool get isOnline => _connectivityStatus != ConnectivityStatus.offline;
  
  void setUser(User? user) {
    _currentUser = user;
    notifyListeners();
  }
  
  void updateConnectivity(ConnectivityStatus status) {
    _connectivityStatus = status;
    notifyListeners();
    
    if (status != ConnectivityStatus.offline) {
      _triggerSync();
    }
  }
  
  void addPendingOperation(PendingOperation operation) {
    _pendingOperations.add(operation);
    notifyListeners();
  }
  
  void removePendingOperation(String id) {
    _pendingOperations.removeWhere((op) => op.id == id);
    notifyListeners();
  }
  
  Future<void> _triggerSync() async {
    if (_isSyncing || _pendingOperations.isEmpty) return;
    
    _isSyncing = true;
    notifyListeners();
    
    // سيتم التعامل مع المزامنة عبر SyncService
    
    _isSyncing = false;
    notifyListeners();
  }
}

enum ConnectivityStatus {
  wifi,
  mobile,
  offline,
  unknown,
}
