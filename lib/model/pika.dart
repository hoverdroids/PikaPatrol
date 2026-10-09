class Pika {

  String species;
  String description;
  String imagePath;
  String moreInfoLink;
  // Who took the photo, shown under the description
  String? photoCredit;

  Pika(this.species, this.description, this.imagePath, this.moreInfoLink, {this.photoCredit});
}