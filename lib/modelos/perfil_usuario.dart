import 'dart:convert';

class UserProfile {
  final String name;
  final String email;
  final String bio;
  final List<String> alergias;
  final List<String> dietas;
  final List<String> cozinhas;
  final int? avatarIndex;

  const UserProfile({
    required this.name,
    required this.email,
    this.bio = '',
    this.alergias = const [],
    this.dietas = const [],
    this.cozinhas = const [],
    this.avatarIndex,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'bio': bio,
        'alergias': alergias,
        'dietas': dietas,
        'cozinhas': cozinhas,
        'avatarIndex': avatarIndex,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        name: json['name'] as String? ?? 'Chef',
        email: json['email'] as String? ?? '',
        bio: json['bio'] as String? ?? '',
        alergias: (json['alergias'] as List<dynamic>?)?.cast<String>() ?? [],
        dietas: (json['dietas'] as List<dynamic>?)?.cast<String>() ?? [],
        cozinhas: (json['cozinhas'] as List<dynamic>?)?.cast<String>() ?? [],
        avatarIndex: json['avatarIndex'] as int?,
      );

  String toJsonString() => jsonEncode(toJson());
  factory UserProfile.fromJsonString(String str) =>
      UserProfile.fromJson(jsonDecode(str) as Map<String, dynamic>);
}
