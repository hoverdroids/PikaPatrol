// ignore_for_file: non_constant_identifier_names

import 'package:pika_patrol/model/pika.dart';

class PikaData {

  static List<String> PIKA_SPECIES = PIKAS.map((pika) => pika.species).toList();

  static const String PIKA_SPECIES_DEFAULT = "American Pika";

  static List<Pika> PIKAS = [
    Pika(
      "americanPika",
      "americanPikaDetails",
      "american_pika.jpeg",
      "https://en.wikipedia.org/wiki/American_pika"
    ),
    Pika(
      "collaredPika",
      "collaredPikaDetails",
      "collared_pika.jpg",
      "https://en.wikipedia.org/wiki/Collared_pika"
    )
    /*Pika(
      "Ili Pika",
      "The Ili pika is a species of mammal in the family Ochotonidae, endemic to northwest China. After its discovery in 1983, it was studied for a decade. Increased temperatures, likely from global warming, and increased grazing pressure may have caused the rapid decline in population",
      "ili_pika.jpeg",
      "https://en.wikipedia.org/wiki/Ili_pika"
    ),
    Pika(
      "Northern Pika",
      "The northern pika is a species of pika found across mountainous regions of northern Asia, from the Ural Mountains to northern Japan and south through Mongolia, Manchuria and northern Korea. An adult northern pika has a body length of 12.5–18.5 centimeters, and a tail of 0.5–1.2 centimeters",
      "northern_pika.jpeg",
      "https://en.wikipedia.org/wiki/Northern_pika"
    ),
    Pika(
      "Helan Shan Pika",
      "The Helan Shan pika or silver pika is a species of mammal in the pika family, Ochotonidae. It is endemic to China where it is found in a small region of the Helan Mountains. It is listed as 'Endangered' in the IUCN Red List of Threatened Species as of 2016",
      "helan_shan_pika.jpeg",
      "https://en.wikipedia.org/wiki/Helan_Shan_pika"
    ),
    Pika(
      "Steppe Pika",
      "The steppe pika is a small mammal of the pika family, Ochotonidae. It is found in the steppes of southern Russia and northern Kazakhstan.",
      "steppe_pika.webp",
      "https://en.wikipedia.org/wiki/Steppe_pika"
    ),
    Pika(
      "Plateau Pika",
      "The plateau pika, also known as the black-lipped pika, is a species of mammal in the pika family, Ochotonidae. It is a small diurnal and non-hibernating mammal weighing about 140 g when fully grown. The animals are reddish tan on the top-side with more of a whitish yellow on their under-belly.",
      "plateau_pika.jpg",
      "https://en.wikipedia.org/wiki/Plateau_pika"
    ),
    Pika(
      "Alpine Pika",
      "The alpine pika is a species of small mammal in the pika family, Ochotonidae. The summer pelage of different subspecies varies drastically but, in general, it is dark or cinnamon brown, turning to grey with a yellowish tinge during the winter.",
      "alpine_pika.jpg",
      "https://en.wikipedia.org/wiki/Alpine_pika"
    ),
    Pika(
      "Koslov's Pika",
      "Koslov's pika or Kozlov's pika is a species of mammal in the family Ochotonidae. It is endemic to China. Its natural habitat is tundra. It is threatened by habitat loss. Kozlov's pika are herbivores, they are known as 'ecosystem engineers' as they're known to promote diversity of different plants species.",
      "koslovs_pika.jpeg",
      "https://en.wikipedia.org/wiki/Koslov%27s_pika"
    )*/
  ];

  static const List<String> OTHER_ANIMALS_PRESENT =  ["Marmots", "Weasels", "Woodrats", "Mountain Goats", "Cattle", "Ptarmigans", "Raptors", "Brown Capped Rosy Finch", "Bats", "Other"];

  static const List<String> SHARED_WITH_PROJECTS = ["Colorado Pika Project", "Rocky Mountain Wild", "Denver Zoo", "IF/THEN", "Cascades Pika Watch", "PikaNET (Mountain Studies Institute)"];

  static const List<String> SHARED_WITH_PROJECTS_DEFAULT = SHARED_WITH_PROJECTS;//Share with all sponsors by default
}