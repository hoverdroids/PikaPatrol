class AppUserProfile {

  final String? uid;
  final String firstName;
  final String lastName;
  final String tagline;
  final String pronouns;
  final String organization;
  final String address;
  final String city;
  final String state;
  final String zip;
  final bool frppOptIn;
  final bool rmwOptIn;
  final bool dzOptIn;
  final List<String> roles;

  AppUserProfile(
    this.firstName,
    this.lastName,
    {
      this.uid,
      this.tagline = "",
      this.pronouns = "",
      this.organization = "",
      this.address = "",
      this.city = "",
      this.state = "",
      this.zip = "",
      this.frppOptIn = false,
      this.rmwOptIn = false,
      this.dzOptIn = false,
      this.roles = const <String>[]
    }
  );

  bool areRequiredFieldsValid() {
    return firstName.isNotEmpty && lastName.isNotEmpty && zip.isNotEmpty;
  }
  
  AppUserProfile copy(
    {
      String? firstName,
      String? lastName,
      String? uid,
      String? tagline,
      String? pronouns,
      String? organization,
      String? address,
      String? city,
      String? state,
      String? zip,
      bool? frppOptIn,
      bool? rmwOptIn,
      bool? dzOptIn,
      List<String>? roles
    }
  ) => AppUserProfile(
    firstName ?? this.firstName,
    lastName ?? this.lastName,
    uid: uid ?? this.uid,
    tagline: tagline ?? this.tagline,
    pronouns: pronouns ?? this.pronouns,
    organization: organization ?? this.organization,
    address: address ?? this.address,
    city: city ?? this.city,
    state: state ?? this.state,
    zip: zip ?? this.zip,
    frppOptIn: frppOptIn ?? this.frppOptIn,
    rmwOptIn: rmwOptIn ?? this.rmwOptIn,
    dzOptIn: dzOptIn ?? this.dzOptIn,
    roles: roles ?? this.roles
  );
}