class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    this.name,
    this.avatarPath,
  });

  final String id;
  final String email;
  final String role;
  final String? name;
  final String? avatarPath;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'].toString(),
        email: json['email'] as String,
        role: (json['role'] ?? 'friend') as String,
        name: json['name'] as String?,
        avatarPath: json['avatarPath'] as String?,
      );
}

class FamilyItem {
  const FamilyItem(this.data);
  final Map<String, dynamic> data;

  String get id => data['id'].toString();
  String get title => (data['titulo'] ?? data['title'] ?? data['url'] ?? 'Item').toString();
  String get subtitle => (data['conteudo'] ?? data['artista'] ?? data['body'] ?? data['texto'] ?? '').toString();
}
