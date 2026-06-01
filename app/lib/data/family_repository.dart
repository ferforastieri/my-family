import '../core/socket/socket_client.dart';
import 'models.dart';

class FamilyRepository {
  FamilyRepository(this.socket);

  final SocketClient socket;

  Future<List<FamilyItem>> list(String resource) async {
    final rows = await socket.emitAck<List<dynamic>>('$resource.list');
    return rows.map((row) => FamilyItem(Map<String, dynamic>.from(row as Map))).toList();
  }

  Future<FamilyItem> create(String resource, Map<String, dynamic> data) async {
    final row = await socket.emitAck<Map<String, dynamic>>('$resource.create', data);
    return FamilyItem(Map<String, dynamic>.from(row));
  }

  Future<FamilyItem> update(String resource, String id, Map<String, dynamic> data) async {
    final row = await socket.emitAck<Map<String, dynamic>>('$resource.update', {'id': id, 'data': data});
    return FamilyItem(Map<String, dynamic>.from(row));
  }

  Future<void> delete(String resource, String id) async {
    await socket.emitAck<Map<String, dynamic>>('$resource.delete', {'id': id});
  }
}
