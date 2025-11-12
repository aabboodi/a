// lib/services/sync_service.dart
class SyncService {
  final HiveBox localDB;
  final ApiService api;
  final ConnectivityService connectivity;
  
  // قائمة انتظار العمليات
  final Queue<PendingOperation> _operationQueue = Queue();
  StreamSubscription? _connectivitySubscription;
  Timer? _syncTimer;
  
  bool _isSyncing = false;
  
  SyncService({
    required this.localDB,
    required this.api,
    required this.connectivity,
  });
  
  void initialize() {
    // تحميل العمليات المعلقة من التخزين المحلي
    _loadPendingOperations();
    
    // مراقبة الاتصال
    _connectivitySubscription = connectivity.onConnectivityChanged.listen(
      (status) {
        if (status != ConnectivityResult.none) {
          _startSync();
        }
      },
    );
    
    // محاولة المزامنة كل 30 ثانية
    _syncTimer = Timer.periodic(Duration(seconds: 30), (_) {
      _startSync();
    });
  }
  
  // إضافة عملية جديدة
  Future<void> addOperation(PendingOperation operation) async {
    // حفظ محلياً
    await localDB.put('pending_${operation.id}', operation.toJson());
    
    _operationQueue.add(operation);
    
    // محاولة التنفيذ فوراً إذا كان هناك اتصال
    if (await connectivity.hasConnection()) {
      _startSync();
    }
  }
  
  // بدء المزامنة
  Future<void> _startSync() async {
    if (_isSyncing || _operationQueue.isEmpty) return;
    
    if (!await connectivity.hasConnection()) return;
    
    _isSyncing = true;
    
    while (_operationQueue.isNotEmpty) {
      final operation = _operationQueue.first;
      
      try {
        // تنفيذ العملية
        await _executeOperation(operation);
        
        // إزالة من القائمة والتخزين المحلي
        _operationQueue.removeFirst();
        await localDB.delete('pending_${operation.id}');
        
        print('✓ Operation synced: ${operation.type}');
        
      } catch (e) {
        print('✗ Sync failed: ${operation.type} - $e');
        
        // إذا كانت المشكلة في الشبكة، توقف
        if (e is DioException && e.type == DioExceptionType.connectionTimeout) {
          break;
        }
        
        // إذا كانت المشكلة في البيانات، احذف العملية
        if (e is DioException && e.response?.statusCode == 400) {
          _operationQueue.removeFirst();
          await localDB.delete('pending_${operation.id}');
        }
        
        // توقف بعد 3 محاولات فاشلة متتالية
        if (operation.retryCount >= 3) {
          _operationQueue.removeFirst();
          await localDB.put('failed_${operation.id}', operation.toJson());
          await localDB.delete('pending_${operation.id}');
        } else {
          // زيادة عدد المحاولات
          operation.retryCount++;
          await localDB.put('pending_${operation.id}', operation.toJson());
          break;
        }
      }
    }
    
    _isSyncing = false;
  }
  
  Future<void> _executeOperation(PendingOperation operation) async {
    switch (operation.type) {
      case OperationType.sendMessage:
        await api.post('/messages', operation.data);
        break;
        
      case OperationType.updateGrades:
        await api.post('/classes/${operation.data['classId']}/grades', operation.data);
        break;
        
      case OperationType.addStudent:
        await api.post('/students', operation.data);
        break;
        
      case OperationType.updateAttendance:
        await api.post('/attendance', operation.data);
        break;
        
      default:
        throw Exception('Unknown operation type');
    }
  }
  
  Future<void> _loadPendingOperations() async {
    final keys = localDB.keys.where((k) => k.startsWith('pending_'));
    
    for (final key in keys) {
      final data = await localDB.get(key);
      if (data != null) {
        _operationQueue.add(PendingOperation.fromJson(data));
      }
    }
    
    print('Loaded ${_operationQueue.length} pending operations');
  }
  
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
  }
}

// نموذج العملية المعلقة
class PendingOperation {
  final String id;
  final OperationType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  int retryCount;
  
  PendingOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'data': data,
    'createdAt': createdAt.toIso8601String(),
    'retryCount': retryCount,
  };
  
  factory PendingOperation.fromJson(Map<String, dynamic> json) {
    return PendingOperation(
      id: json['id'],
      type: OperationType.values.byName(json['type']),
      data: json['data'],
      createdAt: DateTime.parse(json['createdAt']),
      retryCount: json['retryCount'] ?? 0,
    );
  }
}

enum OperationType {
  sendMessage,
  updateGrades,
  addStudent,
  updateAttendance,
}
