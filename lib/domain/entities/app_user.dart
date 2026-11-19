class AppUser {
  final String id;
  final String username;
  final String email;
  final String createdAt;
  final String providerId;
  final String photoUrl;

  const AppUser({
    required this.id,
    required this.username,
    required this.email,
    required this.createdAt,
    this.providerId = 'password',
    this.photoUrl = '',
  });
}
