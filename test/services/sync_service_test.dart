// test/services/sync_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class MockApiService extends Mock implements ApiService {}
class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  group('SyncService Tests', () {
    late SyncService syncService;
    late MockApiService mockApi;
    late MockConnectivityService mockConnectivity;
    
    setUp(() {
      mockApi = MockApiService();
      mockConnectivity = MockConnectivityService();
      syncService = SyncService(
        localDB: Hive.box('test'),
        api: mockApi,
        connectivity: mockConnectivity,
      );
    });
    
    test('should add operation to queue when offline', () async {
      when(mockConnectivity.hasConnection()).thenAnswer((_) async => false);
      
      final operation = PendingOperation(
        id: '1',
        type: OperationType.sendMessage,
        data: {'message': 'test'},
        createdAt: DateTime.now(),
      );
      
      await syncService.addOperation(operation);
      
      expect(syncService.pendingOperationsCount, 1);
    });
    
    test('should sync operations when online', () async {
      when(mockConnectivity.hasConnection()).thenAnswer((_) async => true);
      when(mockApi.post(any, any)).thenAnswer((_) async => {'success': true});
      
      final operation = PendingOperation(
        id: '1',
        type: OperationType.sendMessage,
        data: {'message': 'test'},
        createdAt: DateTime.now(),
      );
      
      await syncService.addOperation(operation);
      await Future.delayed(Duration(seconds: 1));
      
      expect(syncService.pendingOperationsCount, 0);
      verify(mockApi.post(any, any)).called(1);
    });
  });
}
