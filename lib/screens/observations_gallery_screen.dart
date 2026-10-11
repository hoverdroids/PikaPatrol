import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:material_themes_widgets/fundamental/texts.dart';
import 'package:provider/provider.dart';

import '../l10n/translations.dart';
import '../model/app_user.dart';
import '../model/observation.dart';
import '../services/observations_service.dart';
import '../utils/media_cache.dart';
import '../utils/thumbnails.dart';
import '../widgets/supporter_dialog.dart';
import '../primitives/overlay_mode.dart';
import '../widgets/universal_image.dart';
import 'observation_screen.dart';

typedef _Photo = ({String url, Observation observation});

// Every photo the viewer can see, newest observation first: the user's own, or everyone's for
// supporters and admins. The grid shows small thumbnails (see thumbnails.dart) and keeps them on
// the phone, so scrolling back costs nothing. Tapping a photo opens its observation.
class ObservationsGalleryScreen extends StatefulWidget {
  const ObservationsGalleryScreen({super.key});

  @override
  State<ObservationsGalleryScreen> createState() => _ObservationsGalleryScreenState();
}

class _ObservationsGalleryScreenState extends State<ObservationsGalleryScreen> {

  late final AppUser? _user = Provider.of<AppUser?>(context, listen: false);
  late final bool _canSeeAll = _user?.canSeeAllObservations ?? false;
  late final Stream<List<Observation>> _observations =
      Provider.of<ObservationsService>(context, listen: false).visibleObservationsStream(includeShared: _canSeeAll);

  @override
  void initState() {
    super.initState();
    if (_canSeeAll) {
      // Only what changed, and at most every 15 minutes
      Provider.of<ObservationsService>(context, listen: false).syncAllObservations();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showSupporterDialog(context, userId: _user?.uid);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final translations = Provider.of<Translations>(context);
    final themes = context.watch<MaterialThemesManager>();

    return Scaffold(
      backgroundColor: themes.getTheme(ThemeGroupType.MOM).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(translations.photoGallery),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24.0),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: ThemedCaption(_canSeeAll ? translations.showingAllObservations : translations.showingYourObservations, type: ThemeGroupType.MOM),
          ),
        ),
      ),
      body: StreamBuilder<List<Observation>>(
        stream: _observations,
        builder: (context, snapshot) {
          final photos = _photosOf(snapshot.data ?? <Observation>[]);
          if (photos.isEmpty) {
            return Center(child: ThemedTitle(translations.noPhotosToShow, type: ThemeGroupType.MOM));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(2.0),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 160.0, mainAxisSpacing: 2.0, crossAxisSpacing: 2.0),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];
              return GestureDetector(
                onTap: () => openObservation(context, photo.observation),
                child: _thumbnail(photo.url),
              );
            },
          );
        },
      ),
    );
  }

  List<_Photo> _photosOf(List<Observation> observations) {
    final newestFirst = [...observations]..sort((a, b) => (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)));
    return [
      for (final observation in newestFirst)
        for (final url in observation.imageUrls ?? const <String>[])
          if (url.isNotEmpty) (url: url, observation: observation),
    ];
  }

  // The small copy if there is one; until the resize extension has made it, the photo itself,
  // decoded at grid size
  Widget _thumbnail(String url) {
    final thumbnail = thumbnailUrl(url);
    final placeholder = Container(color: Colors.black12);
    if (thumbnail == null) {
      return UniversalImage(url, height: double.infinity, overlayMode: OverlayMode.never);
    }
    return CachedNetworkImage(
      imageUrl: thumbnail,
      cacheKey: MediaCache.keyFor(thumbnail),
      cacheManager: MediaCache.manager,
      fit: BoxFit.cover,
      placeholder: (_, __) => placeholder,
      errorWidget: (_, __, ___) => CachedNetworkImage(
        imageUrl: url,
        cacheKey: MediaCache.keyFor(url),
        cacheManager: MediaCache.manager,
        fit: BoxFit.cover,
        memCacheWidth: 400,
        placeholder: (_, __) => placeholder,
        errorWidget: (_, __, ___) => placeholder,
      ),
    );
  }
}
