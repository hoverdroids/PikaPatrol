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
      this.dzOptIn = false
    }
  );

  bool areRequiredFieldsValid() {
    return firstName.isNotEmpty && lastName.isNotEmpty && zip.isNotEmpty;
  }
}