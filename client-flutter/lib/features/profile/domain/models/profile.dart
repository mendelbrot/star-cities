class Profile {
  final String id;
  final String username;

  Profile({
    required this.id,
    required this.username,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'],
      username: map['username'] ?? 'Unknown',
    );
  }
}
