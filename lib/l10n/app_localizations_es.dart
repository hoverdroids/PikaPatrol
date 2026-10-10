// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Pika Patrulla';

  @override
  String get sharedObservationsLine1 => 'Observaciones';

  @override
  String get sharedObservationsLine2 => 'Compartidas';

  @override
  String get sharedObservationsDialogTitle => 'Observaciones Compartidas';

  @override
  String get sharedObservationsDialogDetails =>
      'Las cinco observaciones más recientes subidas al servidor de Pika Patrol por cualquier usuario.';

  @override
  String get cachedObservationsLine1 => 'Mis';

  @override
  String get cachedObservationsLine2 => 'Observaciones';

  @override
  String get cachedObservationsDialogTitle => 'Mis Observaciones';

  @override
  String get cachedObservationsDialogDetails =>
      'Mis observaciones muestra todas las observaciones que has hecho, en este dispositivo y en cualquier otro donde hayas iniciado sesión. Una nube con una marca de verificación (arriba a la izquierda de la tarjeta) significa que se subió y está segura en el servidor. Un reloj significa que solo está guardada en este teléfono y se subirá la próxima vez que tengas conexión. Si eliminas la aplicación antes, se perderán las observaciones que no se hayan subido.';

  @override
  String get viewObservation => 'Ver Observación';

  @override
  String get makeObservation => 'Hacer una Observación';

  @override
  String get latitude => 'Latitud';

  @override
  String get longitude => 'Longitud';

  @override
  String get altitude => 'Altitud (pie)';

  @override
  String get month => 'Mes';

  @override
  String get day => 'Dia';

  @override
  String get year => 'Año';

  @override
  String get species => 'Especie';

  @override
  String get signs => 'Señales';

  @override
  String get pikasDetected => 'Pikas Detectadas';

  @override
  String get distanceToClosestPika => 'Distancia al Pika más Cercano';

  @override
  String get searchDuration => 'Duración de la Búsqueda';

  @override
  String get talusArea => 'Área del Astrágalo';

  @override
  String get temperature => 'Temperatura';

  @override
  String get skies => 'Cielo';

  @override
  String get wind => 'Viento';

  @override
  String get otherAnimalsPresent => 'Otros Animales Presentes';

  @override
  String get sharedWithProjects => 'Compartido con Proyectos';

  @override
  String get siteHistory => 'Historia del Sitio';

  @override
  String get comments => 'Comentarios';

  @override
  String get images => 'Imágenes';

  @override
  String get noImages => 'Sin Imágenes';

  @override
  String get audioRecordings => 'Grabaciones de Audio';

  @override
  String get noAudioRecordings => 'Sin Grabaciones de Audio';

  @override
  String get appHelpAndInfo => 'Ayuda e Información de la Aplicación';

  @override
  String get appHelpAndInfoUrl =>
      'https://pikapartners.org/pika-patrol-tutorials/';

  @override
  String get identifyingPikasAndTheirSigns =>
      'Identificando Pikas y Sus Signos';

  @override
  String get mapOfPikaObservations => 'Mapa de Observaciones de Pika';

  @override
  String get mapOfPikaObservationsUrl =>
      'https://pikapartners.org/pikapatrolmap/';

  @override
  String get takeClimateAction => 'Tomar Medidas Climáticas';

  @override
  String get takeClimateActionUrl => 'https://pikapartners.org/carbon/';

  @override
  String get sponsorsAndSupport => 'Patrocinadores y Apoyo';

  @override
  String get email => 'Correo Electrónico';

  @override
  String get emailCannotBeEmpty => 'El correo electrónico no puede estar vacío';

  @override
  String get password => 'Contraseña';

  @override
  String get passwordCannotBeEmpty => 'La contraseña no puede estar vacía';

  @override
  String get firstName => 'Nombre de Pila';

  @override
  String get lastName => 'Apellido';

  @override
  String get tagline => 'Lema';

  @override
  String get pronouns => 'Pronombres';

  @override
  String get organization => 'Organización';

  @override
  String get address => 'Dirección';

  @override
  String get city => 'Ciudad';

  @override
  String get state => 'Estado';

  @override
  String get zip => 'Código Postal';

  @override
  String get deleteAccount => 'Borrar Cuenta';

  @override
  String get deleteAccountDialogTitle => 'Borrar Cuenta';

  @override
  String get deleteAccountDialogDetails =>
      '¿Estás seguro de que deseas eliminar tu cuenta? Esto no se puede deshacer. Sus observaciones cargadas permanecerán en el servidor. Las observaciones locales que no se hayan cargado se eliminarán de su dispositivo.';

  @override
  String get accountDeleted => 'Cuenta Borrada';

  @override
  String get edit => 'Editar';

  @override
  String get login => 'Acceso';

  @override
  String get logout => 'Cerrar Sesión';

  @override
  String get register => 'Registro';

  @override
  String get registered => 'Registrado';

  @override
  String get forgotPassword => 'Has Olvidado tu Contraseña';

  @override
  String get americanPika => 'Pika Americano';

  @override
  String get americanPikaDetails =>
      'La pika americana, una especie diurna de pika, se encuentra en las montañas del oeste de América del Norte, generalmente en campos de rocas en la línea de árboles o por encima de ella. Son parientes herbívoros y más pequeños de los conejos y las liebres.';

  @override
  String get collaredPika => 'Pika con Cuello';

  @override
  String get collaredPikaDetails =>
      'Si estás en Alaska o en partes del norte de Canadá, es posible que veas una especie diferente de pika, ¡la pika de collar! Las pikas con collar tienen aproximadamente el mismo tamaño y forma que sus primos americanos, pero tienen un \'collar\'S grisáceo distintivo cerca de los hombros y el cuello. Su llamada también es distinta de la del pika americano, pero sus montones de heno y de excremento tienen el mismo aspecto.';

  @override
  String get iliPika => 'Ili Pika';

  @override
  String get northernPika => 'Pika del Norte';

  @override
  String get helanShanPika => 'Helan Shan Pika';

  @override
  String get steppePika => 'Estepa Pika';

  @override
  String get plateauPika => 'Meseta Pika';

  @override
  String get alpinePika => 'Pika Alpina';

  @override
  String get koslovsPika => 'Pika de Koslov';

  @override
  String get sawPika => 'Pika Visto';

  @override
  String get heardPikaCalls => 'Escuché Llamadas de Pika';

  @override
  String get haypileOld => 'Pajar: Viejo';

  @override
  String get haypileNew => 'Pajar: Nuevo';

  @override
  String get haypileOther => 'Pajar: Otro';

  @override
  String get scatOld => 'Caca: Viejo';

  @override
  String get scatNew => 'Caca: Nuevo';

  @override
  String get scatOther => 'Caca: Otro';

  @override
  String get showHints => 'Muestra Pistas';

  @override
  String get cold => 'Frío: <45°F';

  @override
  String get cool => 'Frío: 45 - 60°F';

  @override
  String get warm => 'Cálido: 60 - 75°F';

  @override
  String get hot => 'Caliente: >75°F';

  @override
  String get clear => 'Despejados';

  @override
  String get partlyCloudy => 'Parcialmente Nublado';

  @override
  String get overcast => 'Nublado';

  @override
  String get rainDrizzle => 'Lluvia/Llovizna';

  @override
  String get snow => 'Nieve';

  @override
  String get lowBendsGrasses => 'Bajo: Curvas de Hierbas';

  @override
  String get mediumBendsBranches => 'Medio: Dobla Ramas';

  @override
  String get highBendsTrees => 'Alto: Árboles Curvados';

  @override
  String get marmots => 'Marmotas';

  @override
  String get weasels => 'Weasels';

  @override
  String get woodrats => 'Comadrejas';

  @override
  String get mountainGoats => 'Cabras de Montaña';

  @override
  String get cattle => 'Ganado';

  @override
  String get ptarmigans => 'Perdices Blancas';

  @override
  String get raptors => 'Rapaces';

  @override
  String get brownCappedRosyFinch => 'Pinzón Rosado de Cabeza Marrón';

  @override
  String get bats => 'Murciélagos';

  @override
  String get other => 'Otro';

  @override
  String get inPartnershipWith => 'En\nCamaradería\nCon';

  @override
  String get enterRequiredFields => 'Debes ingresar los campos requeridos';

  @override
  String get emptyUserProfile => 'Perfil de Usuario Vacío';

  @override
  String get coloradoPikaProject => 'Colorado Pika Project';

  @override
  String get coloradoPikaProjectUrl => 'http://www.pikapartners.org/';

  @override
  String get rockyMountainWild => 'Rocky Mountain Wild';

  @override
  String get rockyMountainWildUrl => 'https://rockymountainwild.org/';

  @override
  String get denverZoo => 'Denver Zoo';

  @override
  String get denverZooUrl => 'https://denverzoo.org/';

  @override
  String get ifThen => 'IF/THEN';

  @override
  String get ifThenUrl => 'https://www.ifthenshecan.org/';

  @override
  String get canadianPikaProject => 'Canadian Pika Project';

  @override
  String get canadianPikaProjectUrl =>
      'https://blogs.ubc.ca/russellolab/canadian-pika-project/';

  @override
  String get appVersion => 'Versión de la Aplicación';

  @override
  String get ok => 'OK';

  @override
  String get couldNotSignInWithThoseCredentials =>
      'No se pudo iniciar sesión con esas credenciales';

  @override
  String get cannotSignInNoConnection =>
      'No puedo iniciar sesión. No estoy conectado a Internet.';

  @override
  String get successfullyLoggedIn => 'Iniciado sesión exitosamente';

  @override
  String get invalidEmailCannotSendPasswordResetEmail =>
      'Email inválido; no puedo enviar un correo electrónico para restablecer la contraseña';

  @override
  String get passwordResetEmailSent =>
      'Correo electrónico de restablecimiento de contraseña enviado';

  @override
  String get passwordResetEmailCouldNotBeSent =>
      'No se pudo enviar el correo electrónico para restablecer la contraseña';

  @override
  String get initialized => 'Inicializado';

  @override
  String get locationTrackingDialogTitle => 'Seguimiento de Ubicación';

  @override
  String get locationTrackingDialogDescription =>
      'Pika Patrol registra la ubicación actual cuando se registra una observación para determinar dónde ocurrió la observación. La observación, incluida la ubicación guardada, se envía en segundo plano a nuestros servidores cuando hay WiFi disponible.';

  @override
  String get noConnectionFoundObservationSavedLocally =>
      'No se encontró ninguna conexión.\nObservación guardada localmente.';

  @override
  String get youMustLoginToUploadAnObservationObservationSavedLocally =>
      'Debe iniciar sesión para cargar una observación.\nObservación guardada localmente.';

  @override
  String get noRecordingsToPlay => 'No hay grabaciones para reproducir';

  @override
  String get fetchingLocation => 'Buscando ubicación ...';

  @override
  String get location => 'Ubicación';

  @override
  String get indigenousTerritories => 'Territorios Indígenas';

  @override
  String get indigenousLanguages => 'Idiomas Indígenas';

  @override
  String get lookingUpIndigenousTerritories =>
      'Buscando territorios indígenas...';

  @override
  String get noIndigenousTerritoryFound =>
      'No se encontró territorio indígena para esta ubicación';

  @override
  String get failedToFetchTerritoryData =>
      'Error al obtener datos del territorio';

  @override
  String get cannotRequestIndigenousTerritoriesOffline =>
      'No se pueden solicitar territorios indígenas sin conexión';

  @override
  String get associateLocalObservationsDialogTitle =>
      'Observaciones no asociadas a tu cuenta';

  @override
  String get associateLocalObservationsDialogDescription =>
      'Tienes observaciones en este dispositivo que se hicieron sin haber iniciado sesión. ¿Te gustaría asociarlas con tu cuenta?';

  @override
  String get associateLocalObservations => 'Asociar';

  @override
  String get doNotAssociateLocalObservations => 'Ahora no';

  @override
  String get siteName => 'Nombre del Sitio';

  @override
  String get january => 'Enero';

  @override
  String get february => 'Febrero';

  @override
  String get march => 'Marzo';

  @override
  String get april => 'Abril';

  @override
  String get may => 'Puede';

  @override
  String get june => 'Junio';

  @override
  String get july => 'Julio';

  @override
  String get august => 'Agosto';

  @override
  String get september => 'Septiembre';

  @override
  String get october => 'Octubre';

  @override
  String get november => 'Noviembre';

  @override
  String get december => 'Diciembre';

  @override
  String get delete => 'Borrar';

  @override
  String get couldNotOpenRecorder =>
      'No se pudo abrir la grabadora.\nDebes aceptar los permisos de audio.';

  @override
  String get didNotAddImage => 'No agregué imagen. Ya está en la lista.';

  @override
  String get didNotAddAudio => 'No agregué audio. Ya está en la lista.';

  @override
  String get unsupportedOperation => 'Operación no compatible';

  @override
  String get errorWhenTryingToCropImage =>
      'Error al intentar recortar la imagen';

  @override
  String get couldNotOpenCameraAcceptCameraPermissions =>
      'No se pudo abrir la cámara.\nDebes aceptar los permisos de la cámara.';

  @override
  String get errorWhenTryingToTakePicture => 'Error al intentar tomar una foto';

  @override
  String get searchArea => 'Área de Búsqueda';

  @override
  String get addAnotherAnimalDialogTitle => 'Añadir animal(es)';

  @override
  String get addAnotherAnimalDialogDescription => '(separado con comas)';

  @override
  String get addAnotherProjectDialogTitle => 'Agregar proyecto(s)';

  @override
  String get addAnotherProjectDialogDescription => '(separado con comas)';

  @override
  String get siteHistoryHint =>
      'Anota cualquier historial que hayas tenido con este sitio.';

  @override
  String get anyAdditionalObservations => 'Cualquier observación adicional';

  @override
  String get addAnotherSpeciesDialogTitle => 'Añadir especies';

  @override
  String get addAnotherSpeciesDialogDescription => '(separado con comas)';

  @override
  String get noObservationsFound => 'No se Encontraron Observaciones';

  @override
  String get uploadingObservations => 'Subiendo observaciones';

  @override
  String get couldNotUploadObservationsNoDataConnection =>
      'No se pudieron cargar las observaciones. Sin conexión de datos.';

  @override
  String get identifyingPikasAndTheirSignsOnboardingTitle =>
      'Identificando Pikas\n&\nSu Signo';

  @override
  String get identifyingPikasAndTheirSignsOnboardingDetails =>
      'Si hay pikas presentes en un desprendimiento de rocas, son fáciles de detectar utilizando muchos tipos de señales únicas. Aquí tienes una breve guía que te ayudará a identificar las pikas.';

  @override
  String get sightOnboardingTitle => 'Vista';

  @override
  String get sightOnboardingDetails =>
      'Las pikas tienen aproximadamente el tamaño y la forma de una papa. Tienen pelaje de color grisáceo a marrón canela y grandes orejas de \'Mickey Mouse\' con un borde blanco alrededor del exterior. No tienen cola visible. Viajan a través del deslizamiento de rocas por encima y por debajo de las rocas.';

  @override
  String get juvenileOnboardingTitle => 'Juveniles';

  @override
  String get juvenileOnboardingDetails =>
      'Las pikas juveniles tienden a ser más pequeñas y de un color gris más uniforme. Esto se debe a que están en su primera capa de pelaje, por lo que aún no han mudado. Sus llamadas también son más suaves y agudas que las de los adultos.';

  @override
  String get soundOnboardingTitle => '¡Escúchalos Rugir!';

  @override
  String get soundOnboardingDetails =>
      'Las pikas emiten chirridos de alarma por varias razones: para advertir a otras pikas sobre depredadores como los halcones y para mantener a otros fuera de su territorio. Los machos adultos también pueden hacer llamadas largas, que tienen un tono ligeramente más alto que las llamadas cortas y pueden durar hasta un minuto. Las llamadas varían regionalmente, por lo que la llamada que escuche en una parte del estado puede no sonar igual que las llamadas que escuche en otras partes. Consejo profesional: muchas veces los pikas responden a llamadas grabadas, así que si no los ves, ¡intenta reproducir esta llamada con el volumen alto!';

  @override
  String get haypilesOnboardingTitle => 'Montones de Heno';

  @override
  String get haypilesOnboardingDetails =>
      'Los pikas construyen grandes depósitos de alimentos para sobrevivir el invierno, comenzando en el verano y continuando hasta que la vegetación muere en el otoño. Los montones de heno activos generalmente consisten en recortes verdes frescos de pasto y flores silvestres, empaquetados debajo o entre rocas. Por lo general, las pikas construyen un montón de heno nuevo encima de las ramitas u hojas sobrantes de años anteriores, que parecen marrones.';

  @override
  String get scatPileOnboardingTitle => 'Pila de Caca';

  @override
  String get scatPileOnboardingDetails =>
      'Los pikas depositan dos tipos de excrementos. El más común es una bolita dura, redonda y marrón que tiene aproximadamente el tamaño y la forma de un grano de pimienta. Estos “gránulos fecales” generalmente se encuentran debajo de una gran roca en los sitios de letrinas, que también pueden tener grandes manchas blancas en la roca debido a la orina. Es muy difícil determinar la edad de los gránulos fecales, pero los depósitos más recientes tienden a contener todavía material vegetal verde y tienden a estar colocados en una pila sobre una roca, con los gránulos más nuevos encima. Los gránulos más viejos generalmente se vuelven grises con el tiempo, se deshacen fácilmente y no contienen ningún material vegetal verde.';

  @override
  String get scatOnboardingTitle => 'Caca';

  @override
  String get scatOnboardingDetails =>
      'El segundo tipo de excremento es un hilo de material suave, negro y brillante llamado bolita cecal. ¡Los gránulos fecales se vuelven a ingerir porque en realidad son más nutritivos que las plantas almacenadas en montones de heno! Estos gránulos a veces se encuentran almacenados en montones de heno (normalmente esparcidos sobre una roca o una planta escondida), pero rara vez se encuentran en letrinas.';

  @override
  String get unsureMoreThanOne => 'Inseguro. Más de 1';

  @override
  String get smallerThanTennisCourt => 'Más Pequeño que la Pista de Tenis';

  @override
  String get tennisCourtToBaseballInfield =>
      'Desde Cancha de Tenis Hasta Campo de Béisbol';

  @override
  String get baseballInfieldToFootballField =>
      'Del Campo de Béisbol al Campo de Fútbol';

  @override
  String get largerThanFootballField => 'Más Grande que un Campo de Fútbol';

  @override
  String get lessThan3000Feet => '<3,000 pie²';

  @override
  String get threeThousandToTenThousandFeet => '3,000 - 10,000 pie²';

  @override
  String get tenThousandToFiftyThousandFeet => '10,000 - 50,000 pie²';

  @override
  String get greaterThanOneAcre => '> 1 acre';

  @override
  String get lessThan10Feet => '<10ft';

  @override
  String get tenTo30Feet => '10 - 30 ft';

  @override
  String get thirtyToOneHundredFeet => '30 - 100 ft';

  @override
  String get moreThanOneHundredFeet => '>100 ft';

  @override
  String get lessThanFiveMin => '<5 min';

  @override
  String get fiveToTenMin => '5 - 10 min';

  @override
  String get tenToTwentyMin => '10 - 20 min';

  @override
  String get twentyToThirtyMin => '20 - 30 min';

  @override
  String get moreThanThirtyMin => '>30 min';

  @override
  String get adminSettings => 'Configuración de Administrador';

  @override
  String get userProfiles => 'Perfiles de Usuario';

  @override
  String get exportFirebaseUserProfilesToGoogleSheets =>
      'Exportar perfiles de usuario de Firebase a Google Sheets';

  @override
  String get exportFirebaseUserProfilesToGoogleSheetsDialogTitle =>
      '¿Exportar perfiles de usuario de Firebase a Google Sheets?';

  @override
  String get exportFirebaseUserProfilesToGoogleSheetsDialogDescription =>
      'Esto sincronizará todos los datos del perfil de usuario de Firebase con las hojas de Google, lo que contará para la cuota tanto de la API de Firebase como de la API de Google Cloud.';

  @override
  String get exportFirebaseObservationsToGoogleSheets =>
      'Exportar observaciones de Firebase a Google Sheets';

  @override
  String get exportFirebaseObservationsToGoogleSheetsDialogTitle =>
      '¿Exportar observaciones de Firebase a Google Sheets?';

  @override
  String get exportFirebaseObservationsToGoogleSheetsDialogDescription =>
      'Esto sincronizará todos los datos de observaciones de Firebase con las hojas de Google, lo que contará para la cuota tanto de la API de Firebase como de la API de Google Cloud.';

  @override
  String get profileIsAlreadyUpToDate => 'El perfil ya está actualizado';

  @override
  String get couldNotRetrieveLocationEnableGps =>
      'No se pudo recuperar la ubicación.\nHabilite el GPS e intente guardar nuevamente.';

  @override
  String get locationServicesAreDisabled =>
      'Los servicios de ubicación están deshabilitados.';

  @override
  String get youMustGrantLocationPermissions =>
      'Debes otorgar permisos de ubicación.';

  @override
  String get locationPermissionsAreDenied =>
      'Se deniegan los permisos de ubicación';

  @override
  String get locationPermissionsArePermanentlyDenied =>
      'Los permisos de ubicación están permanentemente denegados, no podemos solicitar permisos.';

  @override
  String get couldNotRetrieveLocationFromGps =>
      'No se pudo recuperar la ubicación del GPS.';

  @override
  String get profileUpdated => 'Perfil actualizado';

  @override
  String get profile => 'Perfil';

  @override
  String get invalidEmail => 'Correo electronico es requerido';

  @override
  String get invalidPassword => 'Ingrese una contraseña de más de 6 caracteres';

  @override
  String get invalidFirstName => 'Se requiere el primer nombre';

  @override
  String get invalidLastName => 'Se requiere apellido';

  @override
  String get invalidZip => 'Se requiere código postal';

  @override
  String get save => 'Ahorrar';

  @override
  String get deleteObservationDialogTitle => '¿Eliminar observación?';

  @override
  String get deleteObservationDialogDescription =>
      '¿Está seguro de que desea eliminar esta observación y todos los datos asociados, incluidas imágenes y archivos de audio?';

  @override
  String get cancel => 'Cancelar';

  @override
  String get observationDeleted => 'Observación eliminada';

  @override
  String get observationNotDeleted => 'Observación no eliminada';

  @override
  String get initializeGoogleSheets => 'Inicializar hojas de cálculo de Google';

  @override
  String get localObservationsNeedUploadedDialogTitle =>
      'Es necesario cargar las observaciones fuera de línea.';

  @override
  String get localObservationsNeedUploadedDialogDescription =>
      'Las observaciones que se realizaron fuera de línea aún no se han cargado. ¿Cargar ahora?';

  @override
  String get observationSavedSuccessfully =>
      '¡Gracias! Tu observación se subió.';

  @override
  String get unknownErrorUploadingToServerObservationSavedLocally =>
      'Error desconocido al subir al servidor.\nObservación guardada localmente.';

  @override
  String get fillInAllFormFields => 'Rellene todos los campos del formulario';

  @override
  String get userSettings => 'Configuración de Usuario';

  @override
  String get indigenousMap => 'Mapa indígena';

  @override
  String get indigenousMapDescription =>
      'Abrir automáticamente el mapa de Native Land después de obtener el GPS';

  @override
  String get splashScreen => 'Pantalla de bienvenida';

  @override
  String get splashScreenDescription =>
      'Mostrar las pantallas de presentación de los patrocinadores al abrir la aplicación';

  @override
  String get units => 'Unidades';

  @override
  String get imperial => 'Imperial';

  @override
  String get metric => 'Métrico';

  @override
  String get feet => 'pies';

  @override
  String get meters => 'metros';

  @override
  String get altitudeMetric => 'Altitud (m)';

  @override
  String get defaultObservation => 'Observación predeterminada';

  @override
  String get defaultObservationDescription =>
      'Editar los valores predeterminados para nuevas observaciones';

  @override
  String get defaultObservationSaved => 'Observación predeterminada guardada';

  @override
  String get coldMetric => 'Frío: <7°C';

  @override
  String get coolMetric => 'Frío: 7 - 16°C';

  @override
  String get warmMetric => 'Cálido: 16 - 24°C';

  @override
  String get hotMetric => 'Caliente: >24°C';

  @override
  String get lessThan3000FeetMetric => '<280 m²';

  @override
  String get threeThousandToTenThousandFeetMetric => '280 - 930 m²';

  @override
  String get tenThousandToFiftyThousandFeetMetric => '930 - 4,600 m²';

  @override
  String get greaterThanOneAcreMetric => '> 0,4 ha';

  @override
  String get lessThan10FeetMetric => '<3 m';

  @override
  String get tenTo30FeetMetric => '3 - 9 m';

  @override
  String get thirtyToOneHundredFeetMetric => '9 - 30 m';

  @override
  String get moreThanOneHundredFeetMetric => '>30 m';

  @override
  String get deleteAccountEnterPassword =>
      'Ingresa tu contraseña para confirmar.';

  @override
  String get deleteAccountWrongPassword =>
      'Esa contraseña no funcionó, así que tu cuenta no se eliminó.';

  @override
  String get signInWithGoogle => 'Iniciar sesión con Google';

  @override
  String get signInWithApple => 'Iniciar sesión con Apple';

  @override
  String get couldNotSignIn => 'No se pudo iniciar sesión. Inténtalo de nuevo.';

  @override
  String get traditionalTerritoryOf => 'Territorio tradicional del pueblo %s';

  @override
  String get nativeLandSource => 'Fuente: Native Land Digital';

  @override
  String get incidental => 'Incidental';

  @override
  String get deleteImageDialogTitle => '¿Eliminar esta foto?';

  @override
  String get deleteAudioDialogTitle => '¿Eliminar esta grabación?';

  @override
  String get deleteMediaDialogDescription =>
      'Esto no se puede deshacer. Se borra del servidor cuando guarde la observación.';

  @override
  String get unusedFiles => 'Archivos sin usar';

  @override
  String get unusedFilesDescription =>
      'Fotos y grabaciones en el almacenamiento que ninguna observación usa y que no coinciden con ninguna en un 20% o más. Se omiten los archivos del último día por si una subida aún no ha terminado. Se revisaron %observations% observaciones y %files% archivos.';

  @override
  String get unusedFilesSelected => '%count% seleccionados, %size%';

  @override
  String get noUnusedFiles => 'No se encontraron archivos sin usar.';

  @override
  String get selectAll => 'Seleccionar todo';

  @override
  String get deleteSelected => 'Eliminar selección';

  @override
  String get deleteUnusedFilesDialogTitle => '¿Eliminar %count% archivos?';

  @override
  String get deleteUnusedFilesDialogDescription =>
      'Se eliminan del almacenamiento de forma permanente. Esto no se puede deshacer.';

  @override
  String get couldNotFindUnusedFiles =>
      'No se pudieron revisar los archivos. Compruebe su conexión e inténtelo de nuevo.';

  @override
  String get someFilesNotDeleted =>
      'Algunos archivos no se pudieron eliminar. Inténtelo más tarde.';

  @override
  String get correlateFiles => 'Relacionar archivos';

  @override
  String get correlateFilesDescription =>
      'Archivos guardados que ninguna observación usa, o cuyo enlace se rompió, cada uno con la observación a la que probablemente pertenece y qué tan segura es la coincidencia. Toque una observación para elegir otra. Marque las que parezcan correctas y repárelas juntas. Se revisaron %observations% observaciones y %files% archivos.';

  @override
  String get checkingFiles => 'Revisando archivos: %done% de %total%';

  @override
  String get fixReasonRefreshLink => 'Mismo archivo; su enlace caducó';

  @override
  String get fixReasonSameName => 'Mismo nombre que el enlace roto';

  @override
  String get fixSelectedLinks => 'Reparar enlaces seleccionados';

  @override
  String get fixLinksDialogTitle => '¿Reparar %count% enlaces?';

  @override
  String get fixLinksDialogDescription =>
      'Cada archivo seleccionado reemplaza el enlace roto de su observación. Nada más cambia en las observaciones y no se borra ningún archivo.';

  @override
  String get noBrokenLinksFound => 'No se encontraron enlaces rotos.';

  @override
  String get linksFixed => 'Se repararon enlaces en %count% observaciones.';

  @override
  String get someLinksNotFixed =>
      'No se pudieron actualizar %count% observaciones. Inténtelo más tarde.';

  @override
  String get matchUploadedWithLinkedFile =>
      'Subido a %time% de un archivo que ya está en esta observación';

  @override
  String get matchMadeNearObservationStart =>
      'Su nombre muestra que se creó a %time% de cuando se empezó esta observación';

  @override
  String get matchUploadedNearSave =>
      'Subido a %time% de cuando se guardó por última vez esta observación';

  @override
  String get matchUploadedAfterObservationDate =>
      'Subido a %time% de la fecha de esta observación';

  @override
  String get matchObservationHasBrokenLink =>
      'Esta observación tiene un enlace roto del mismo tipo';

  @override
  String get matchCloseRunnerUp =>
      'Otra observación coincide casi igual de bien';

  @override
  String get selectAbove90 => 'Seleccionar 90% o más';

  @override
  String get clearSelection => 'Borrar selección';

  @override
  String get otherPossibleObservations => 'Elija la observación';

  @override
  String get scannedAgo =>
      'Revisado hace %time%. Deslice hacia abajo para revisar de nuevo.';

  @override
  String get recordingNameHint => 'Nombre de la grabación';

  @override
  String get couldNotSaveRecording =>
      'No se pudo guardar la grabación. Inténtelo de nuevo.';

  @override
  String get observationOnServer => 'En el servidor. Última subida: %s.';

  @override
  String get observationOnServerNoDate => 'En el servidor.';

  @override
  String get observationWaitingToUpload =>
      'Los cambios están guardados en este teléfono y se subirán la próxima vez que tenga conexión.';

  @override
  String get duplicateObservations => 'Observaciones duplicadas';

  @override
  String get duplicateObservationsDescription =>
      'Observaciones guardadas en el servidor más de una vez: misma persona, iniciadas con menos de un minuto de diferencia, mismo sitio o coordenadas. Elija la copia que se conserva en cada grupo. Recibe todas las fotos, grabaciones y proyectos de las otras copias, que luego se eliminan. No se borra ningún archivo de foto ni de grabación.';

  @override
  String get keepThisCopy => 'Conservar';

  @override
  String get copiesCount => '%count% copias';

  @override
  String get mergeSelected => 'Combinar selección';

  @override
  String get mergeDuplicatesDialogTitle => '¿Combinar %count% grupos?';

  @override
  String get mergeDuplicatesDialogDescription =>
      'Cada copia conservada recibe las fotos, grabaciones y proyectos de sus otras copias, y las otras copias se eliminan del servidor y de las hojas. Esto no se puede deshacer.';

  @override
  String get noDuplicatesFound => 'No se encontraron observaciones duplicadas.';

  @override
  String get duplicatesMerged => 'Se combinaron %count% grupos.';

  @override
  String get someDuplicatesNotMerged =>
      'No se pudieron combinar %count% grupos. Inténtelo más tarde.';

  @override
  String get couldNotLoadObservations =>
      'No se pudieron cargar las observaciones. Compruebe su conexión e inténtelo de nuevo.';

  @override
  String get fileTooLarge => 'Archivo demasiado grande';

  @override
  String get photoTooLargeDescription =>
      'Esta foto pesa %size% MB. Las fotos deben pesar menos de 50 MB para subirse. ¿Añadir una copia más pequeña? La original se queda en tu teléfono.';

  @override
  String get recordingTooLargeDescription =>
      'Esta grabación pesa %size% MB. Las grabaciones deben pesar menos de 50 MB para subirse, así que no se añadió. Prueba con una grabación más corta.';

  @override
  String get makeSmaller => 'Reducir';

  @override
  String get couldNotMakePhotoSmaller =>
      'No se pudo reducir esta foto lo suficiente, así que no se añadió';
}
