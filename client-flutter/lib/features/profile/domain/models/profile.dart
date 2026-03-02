class Profile {
  final String id;
  final String username;
  final String profileIcon;

  Profile({
    required this.id,
    required this.username,
    required this.profileIcon,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'],
      username: map['username'] ?? 'Unknown',
      profileIcon: map['profile_icon'] ?? 'default_icon',
    );
  }
}
