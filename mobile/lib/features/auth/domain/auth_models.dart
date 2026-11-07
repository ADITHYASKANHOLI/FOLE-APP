class StudentUser {
  final String id;
  final String username;
  final String displayName;
  final bool isOrganizer;
  final String? createdAt;

  const StudentUser({
    required this.id,
    required this.username,
    required this.displayName,
    this.isOrganizer = false,
    this.createdAt,
  });

  factory StudentUser.fromJson(Map<String, dynamic> json) {
    return StudentUser(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      displayName: json['display_name']?.toString() ??
          json['username']?.toString() ??
          'Student',
      isOrganizer: json['is_organizer'] == true,
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'display_name': displayName,
        'is_organizer': isOrganizer,
        'created_at': createdAt,
      };
}

class AuthSession {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final int? expiresAt;

  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    this.expiresAt,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['access_token']?.toString() ?? '',
      refreshToken: json['refresh_token']?.toString() ?? '',
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 3600,
      expiresAt: (json['expires_at'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'expires_in': expiresIn,
        'expires_at': expiresAt,
      };
}

class AuthResponse {
  final StudentUser user;
  final AuthSession session;

  const AuthResponse({
    required this.user,
    required this.session,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: StudentUser.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
      session:
          AuthSession.fromJson(json['session'] as Map<String, dynamic>? ?? {}),
    );
  }
}
