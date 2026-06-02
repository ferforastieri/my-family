import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../core/config/app_config.dart';
import '../core/socket/socket_client.dart';
import 'models.dart';

class FamilyRepository {
  FamilyRepository(this.socket);

  final SocketClient socket;

  Future<List<FamilyItem>> list(String resource) async {
    final rows = await socket.emitAck<List<dynamic>>('$resource.list');
    return rows
        .map((row) => FamilyItem(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<FamilyItem> create(String resource, Map<String, dynamic> data) async {
    final row =
        await socket.emitAck<Map<String, dynamic>>('$resource.create', data);
    return FamilyItem(Map<String, dynamic>.from(row));
  }

  Future<FamilyItem> update(
      String resource, String id, Map<String, dynamic> data) async {
    final row = await socket.emitAck<Map<String, dynamic>>(
        '$resource.update', {'id': id, 'data': data});
    return FamilyItem(Map<String, dynamic>.from(row));
  }

  Future<void> delete(String resource, String id) async {
    await socket.emitAck<Map<String, dynamic>>('$resource.delete', {'id': id});
  }

  Future<String> uploadPhotoFile(XFile file) async {
    final request =
        http.MultipartRequest('POST', AppConfig.apiUri('/fotos/upload'));
    final token = socket.token;
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    request.files.add(http.MultipartFile.fromBytes(
        'file', await file.readAsBytes(),
        filename: file.name));

    final response = await request.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(body.isEmpty ? 'Erro ao enviar arquivo.' : body);
    }

    final json = jsonDecode(body) as Map<String, dynamic>;
    final relativePath = json['relativePath']?.toString();
    if (relativePath == null || relativePath.isEmpty) {
      throw Exception('Resposta de upload inválida.');
    }
    return relativePath;
  }
}
