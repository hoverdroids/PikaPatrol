class AppUser {

  final String uid;
  final String? displayName;
  final String? email;
  final bool emailVerified;
  final bool isAnonymous;
  final DateTime? creationTimestamp;
  final DateTime? lastSignInTime;
  final String? phoneNumber;
  final String? photoUrl;
  final String? tenantId;
  final bool isAdmin;

  AppUser({
    required this.uid,
    this.displayName,
    this.email,
    this.emailVerified = false,
    this.isAnonymous = false,
    this.creationTimestamp,
    this.lastSignInTime,
    this.phoneNumber,
    this.photoUrl,
    this.tenantId,
    this.isAdmin = false
  });
}