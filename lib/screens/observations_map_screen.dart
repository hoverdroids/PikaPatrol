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
import '../services/observations_service.dart';
import '../utils/env.dart';
import '../utils/map_clusters.dart';
import '../widgets/supporter_dialog.dart';
import 'observation_screen.dart';

// The tile server comes from .env (MAP_TILE_URL), because the public OpenStreetMap servers don't
// allow app-scale use. OpenStreetMap is only the fallback for testing. See .env.example.
String get _tileUrl {
  final configured = envValue("MAP_TILE_URL");
  return configured.isNotEmpty ? configured : "https://tile.openstreetmap.org/{z}/{x}/{y}.png";
}
String get _tileAttribution {
  final configured = envValue("MAP_TILE_ATTRIBUTION");
  return envValue("MAP_TILE_URL").isNotEmpty && configured.isNotEmpty ? configured : "© OpenStreetMap contributors";
}

// Every observation the viewer can see, as a dot on a map: the user's own, or everyone's for
// supporters and admins. Teal dots found pikas, grey dots didn't. Tapping a dot opens it. Dots
// that would overlap are drawn as one circle with a count; tapping it zooms in.
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

  // Rebuilt only when the dots change; zooming just regroups them
  final MapTileLayerController _markers = MapTileLayerController();
  MapZoomPanBehavior? _zoomPan;
  Object? _locatedKey;
  List<Observation> _located = [];
  List<MapCluster<Observation>> _clusters = [];
  int? _clusteredAtZoom;

  @override
  void dispose() {
    _markers.dispose();
    super.dispose();
  }

  Widget _buildMap(List<Observation> located, Color primary) {
    final key = Object.hashAll(located.map((o) => Object.hash(o.uid, o.latitude, o.longitude, o.pikasDetected)));
    if (key != _locatedKey || _zoomPan == null) {
      _locatedKey = key;
      _located = located;
      final bounds = _boundsOf(located);
      // With zooming on, Syncfusion takes the starting view from the zoom behavior, not the layer
      _zoomPan = MapZoomPanBehavior(
        focalLatLng: bounds == null ? const MapLatLng(45.0, -112.0) : _center(bounds),
        zoomLevel: bounds == null ? 4 : 10,
        latLngBounds: located.length > 1 ? bounds : null,
        minZoomLevel: 2,
        maxZoomLevel: 18,
        enableDoubleTapZooming: true,
        showToolbar: false,
      );
      _clusteredAtZoom = null;
      _clusters = _clusterAt(_zoomPan!.zoomLevel);
      // Fitting to the bounds sets the real starting zoom after the first frame
      WidgetsBinding.instance.addPostFrameCallback((_) => _reclusterFor(_zoomPan?.zoomLevel));
    }

    return SfMaps(
      // A new key when the dots change, so the map rebuilds its markers and refits the view
      key: ValueKey(key),
      layers: [
        MapTileLayer(
          urlTemplate: _tileUrl,
          controller: _markers,
          zoomPanBehavior: _zoomPan,
          initialMarkersCount: _clusters.length,
          onWillZoom: (details) {
            final zoom = details.newZoomLevel;
            WidgetsBinding.instance.addPostFrameCallback((_) => _reclusterFor(zoom));
            return true;
          },
          markerBuilder: (context, index) => _marker(_clusters[index], primary),
        ),
      ],
    );
  }

  List<MapCluster<Observation>> _clusterAt(double zoom) {
    _clusteredAtZoom = zoom.round();
    return clusterPoints(_located, latitude: (o) => o.latitude!, longitude: (o) => o.longitude!, zoom: zoom.roundToDouble());
  }

  // Regroups the dots when the zoom crosses a whole level
  void _reclusterFor(double? zoom) {
    if (!mounted || zoom == null || zoom.round() == _clusteredAtZoom) return;
    _clusters = _clusterAt(zoom);
    _markers.clearMarkers();
    for (var index = 0; index < _clusters.length; index++) {
      _markers.insertMarker(index);
    }
  }

  MapMarker _marker(MapCluster<Observation> cluster, Color primary) {
    if (cluster.isSingle) {
      final observation = cluster.items.first;
      return MapMarker(
        latitude: observation.latitude!,
        longitude: observation.longitude!,
        child: GestureDetector(
          onTap: () => openObservation(context, observation),
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
    }

    // Bigger for more observations, teal if any of them found pikas
    final size = (24.0 + 18.0 * log(cluster.count) / ln10).clamp(24.0, 56.0);
    final anyPikas = cluster.items.any(ObservationStats.hasPikas);
    return MapMarker(
      latitude: cluster.latitude,
      longitude: cluster.longitude,
      child: GestureDetector(
        onTap: () => _zoomInto(cluster),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: (anyPikas ? primary : Colors.grey).withValues(alpha: 0.85),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.0),
            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 2.0)],
          ),
          child: Text("${cluster.count}", style: const TextStyle(color: Colors.white, fontSize: 12.0, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  void _zoomInto(MapCluster<Observation> cluster) {
    final zoomPan = _zoomPan;
    if (zoomPan == null) return;
    zoomPan.focalLatLng = MapLatLng(cluster.latitude, cluster.longitude);
    zoomPan.zoomLevel = min(zoomPan.zoomLevel + 2, zoomPan.maxZoomLevel);
    _reclusterFor(zoomPan.zoomLevel);
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
}
