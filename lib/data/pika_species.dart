// ignore_for_file: non_constant_identifier_names

import 'package:pika_patrol/model/pika.dart';

class PikaSpecies {

  static List<String> PIKA_SPECIES = PIKAS.map((pika) => pika.species).toList();

  static const String PIKA_SPECIES_DEFAULT = "American Pika";

  static List<Pika> PIKAS = [
    Pika("American Pika",
        "The American pika, a diurnal species of pika, is found in the mountains of western North America, usually in boulder fields at or above the tree line. They are herbivorous, smaller relatives of rabbits and hares.",
        "american_pika.jpg",
        "https://en.wikipedia.org/wiki/American_pika"
    ),
    Pika("Collared Pika",
        "The collared pika is a species of mammal in the pika family, Ochotonidae, and part of the order Lagomorpha, which comprises rabbits, hares, and pikas",
        "collared_pika.jpg",
        "https://en.wikipedia.org/wiki/Collared_pika"
    ),
    Pika("Ili Pika",
        "The Ili pika is a species of mammal in the family Ochotonidae, endemic to northwest China. After its discovery in 1983, it was studied for a decade. Increased temperatures, likely from global warming, and increased grazing pressure may have caused the rapid decline in population",
        "ili_pika.jpeg",
        "https://en.wikipedia.org/wiki/Ili_pika"
    ),
    Pika("Northern Pika",
        "The northern pika is a species of pika found across mountainous regions of northern Asia, from the Ural Mountains to northern Japan and south through Mongolia, Manchuria and northern Korea. An adult northern pika has a body length of 12.5–18.5 centimeters, and a tail of 0.5–1.2 centimeters",
        "northern_pika.jpg",
        "https://en.wikipedia.org/wiki/Northern_pika"
    ),
  ];
}