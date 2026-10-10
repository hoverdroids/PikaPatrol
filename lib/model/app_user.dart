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
  // Until when this account is a supporter (a donor to Rocky Mountain Wild); null if it isn't one
  final DateTime? supporterUntil;
  final String? idToken;

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
    this.isAdmin = false,
    this.supporterUntil,
    this.idToken
  });

  // Supporters, and admins, see every observation on the map, dashboard and lists
  bool get isSupporter => supporterUntil?.isAfter(DateTime.now()) ?? false;
  bool get canSeeAllObservations => isAdmin || isSupporter;
}
