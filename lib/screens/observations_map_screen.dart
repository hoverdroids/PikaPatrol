import 'dart:math';

import 'package:flutter/material.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:material_themes_widgets/fundamental/texts.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_maps/maps.dart';

import '../l10n/translations.dart';
import '../model/app_user.dart';
import '../model/observation.dart';
import '../model/observation_stats.dart';
import '../model/observation_view_model.dart';
import '../services/observations_service.dart';
import '../widgets/supporter_dialog.dart';
import 'observation_screen.dart';

// TODO(supporters plan): the public OpenStreetMap tile servers don't allow app-scale use. Swap in a
// keyed tile plan (for example MapTiler or Stadia Maps) and its attribution before 3.6.0 ships.
const String _tileUrl = "https://tile.openstreetmap.org/{z}/{x}/{y}.png";
const String _tileAttribution = "© OpenStreetMap contributors";

// Every observation the viewer can see, as a dot on a map: the user's own, or everyone's for
// supporters and admins. Teal dots found pikas, grey dots didn't. Tapping a dot opens it.
class ObservationsMapScreen extends StatefulWidget {
  const ObservationsMapScreen({super.key});

  @override
  State<ObservationsMapScreen> createState() => _ObservationsMapScreenState();
}

class _ObservationsMapScreenState extends State<ObservationsMapScreen> {

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
    final primary = themes.colorPalette().primary;

    return Scaffold(
      backgroundColor: themes.getTheme(ThemeGroupType.MOM).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(translations.observationsMap),
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
          final observations = snapshot.data ?? <Observation>[];
          final located = observations.where((o) => o.latitude != null && o.longitude != null).toList();
          final unlocated = observations.length - located.length;

          return Stack(
            children: [
              _buildMap(located, primary),
              Positioned(
                left: 8.0,
                bottom: 8.0,
                child: _label(_tileAttribution),
              ),
              if (located.isEmpty)
                Center(child: _label(translations.noObservationsToShow))
              else if (unlocated > 0)
                Positioned(
                  top: 8.0,
                  left: 8.0,
                  right: 64.0,
                  child: _label(translations.observationsWithoutLocation.replaceAll("%count%", "$unlocated")),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _label(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(6.0)),
    child: Text(text, style: const TextStyle(fontSize: 12.0, color: Colors.black87)),
  );

  Widget _buildMap(List<Observation> located, Color primary) {
    final bounds = _boundsOf(located);
    return SfMaps(
      // A new key when the dots change, so the map rebuilds its markers and refits the view
      key: ValueKey(Object.hashAll(located.map((o) => Object.hash(o.uid, o.latitude, o.longitude, o.pikasDetected)))),
      layers: [
        MapTileLayer(
          urlTemplate: _tileUrl,
          // With zooming on, Syncfusion takes the starting view from the zoom behavior, not the layer
          zoomPanBehavior: MapZoomPanBehavior(
            focalLatLng: bounds == null ? const MapLatLng(45.0, -112.0) : _center(bounds),
            zoomLevel: bounds == null ? 4 : 10,
            latLngBounds: located.length > 1 ? bounds : null,
            minZoomLevel: 2,
            maxZoomLevel: 18,
            enableDoubleTapZooming: true,
            showToolbar: false,
          ),
          initialMarkersCount: located.length,
          markerBuilder: (context, index) {
            final observation = located[index];
            return MapMarker(
              latitude: observation.latitude!,
              longitude: observation.longitude!,
              child: GestureDetector(
                onTap: () => _openObservation(observation),
                child: Container(
                  width: 16.0,
                  height: 16.0,
                  decoration: BoxDecoration(
                    color: ObservationStats.hasPikas(observation) ? primary : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.0),
                    boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 2.0)],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  MapLatLngBounds? _boundsOf(List<Observation> located) {
    if (located.isEmpty) return null;
    var north = -90.0, south = 90.0, east = -180.0, west = 180.0;
    for (final observation in located) {
      north = max(north, observation.latitude!);
      south = min(south, observation.latitude!);
      east = max(east, observation.longitude!);
      west = min(west, observation.longitude!);
    }
    // A little margin so edge dots aren't cut off
    final latitudeMargin = max((north - south) * 0.1, 0.01);
    final longitudeMargin = max((east - west) * 0.1, 0.01);
    return MapLatLngBounds(
      MapLatLng(min(north + latitudeMargin, 85.0), min(east + longitudeMargin, 180.0)),
      MapLatLng(max(south - latitudeMargin, -85.0), max(west - longitudeMargin, -180.0)),
    );
  }

  MapLatLng _center(MapLatLngBounds bounds) => MapLatLng(
    (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
    (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
  );

  void _openObservation(Observation observation) {
    final translations = Provider.of<Translations>(context, listen: false);
    final viewModel = ObservationViewModel(observation.copy(), translations);
    Navigator.push(context, MaterialPageRoute(builder: (_) => ObservationScreen(viewModel)));
  }
}
