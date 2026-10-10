import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:material_themes_widgets/fundamental/texts.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../l10n/translations.dart';
import '../model/app_user.dart';
import '../model/observation.dart';
import '../model/observation_stats.dart';
import '../model/observation_view_model.dart';
import '../services/observations_service.dart';
import '../services/settings_service.dart';
import '../utils/geo_utils.dart';
import '../widgets/supporter_dialog.dart';

enum _Period { allTime, last12Months, thisYear }

// Charts of the observations the viewer can see: the user's own, or everyone's for supporters and
// admins. Everything is worked out on the phone from observations it already has; nothing here
// reads Firebase.
class ObservationsDashboardScreen extends StatefulWidget {
  const ObservationsDashboardScreen({super.key});

  @override
  State<ObservationsDashboardScreen> createState() => _ObservationsDashboardScreenState();
}

class _ObservationsDashboardScreenState extends State<ObservationsDashboardScreen> {

  late final AppUser? _user = Provider.of<AppUser?>(context, listen: false);
  late final bool _canSeeAll = _user?.canSeeAllObservations ?? false;
  late final Stream<List<Observation>> _observations =
      Provider.of<ObservationsService>(context, listen: false).visibleObservationsStream(includeShared: _canSeeAll);

  late Translations translations;
  late ObservationViewModel _labels;
  _Period _period = _Period.allTime;
  String? _species;

  @override
  void initState() {
    super.initState();
    if (!_canSeeAll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showSupporterDialog(context, userId: _user?.uid);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    translations = Provider.of<Translations>(context);
    // Turns stored values into the current language, the same way the observation form does
    _labels = ObservationViewModel(Observation(), translations);
    final isMetric = Provider.of<SettingsService>(context).isMetric;
    final themes = context.watch<MaterialThemesManager>();
    final palette = themes.colorPalette();

    return Scaffold(
      backgroundColor: themes.getTheme(ThemeGroupType.MOM).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(translations.dashboard),
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
          final stats = ObservationStats.from(_filter(snapshot.data ?? <Observation>[]));
          final colors = [palette.primary, palette.secondary, Colors.teal.shade200, Colors.brown.shade300, Colors.blueGrey, Colors.amber.shade700];

          return ListView(
            padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 32.0),
            children: [
              _buildFilters(palette.primary),
              _buildTotals(stats, palette.primary),
              if (stats.total == 0)
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(child: ThemedTitle(translations.noObservationsToShow, type: ThemeGroupType.MOM)),
                )
              else ...[
                _card(translations.observationsPerMonth, _buildPerMonth(stats, palette.primary)),
                _card(translations.species, _buildSpecies(stats, colors)),
                if (stats.pikasDetected.isNotEmpty)
                  _card(translations.pikasDetected, _buildColumns(_ordered(stats.pikasDetected, translations.pikasDetectedDefaultValues, _labels.getPikasDetectedLabel), palette.primary)),
                if (stats.signs.isNotEmpty)
                  _card(translations.signs, _buildBars(_ordered(stats.signs, translations.signsDefaultValues, _labels.getSignsLabel), palette.secondary)),
                if (stats.searchDuration.isNotEmpty)
                  _card(translations.searchDuration, _buildBars(_ordered(stats.searchDuration, translations.searchDurationDefaultValues, _labels.getSearchDurationLabel), palette.primary)),
                if (stats.elevationsInMeters.isNotEmpty)
                  _card(isMetric ? translations.altitudeMetric : translations.altitude, _buildColumns(_elevationBins(stats, isMetric), palette.secondary)),
                if (stats.projects.isNotEmpty)
                  _card(translations.sharedWithProjects, _buildBars(_byCount(stats.projects), palette.primary)),
              ],
            ],
          );
        },
      ),
    );
  }

  List<Observation> _filter(List<Observation> observations) {
    final now = DateTime.now();
    final from = switch (_period) {
      _Period.allTime => null,
      _Period.last12Months => DateTime(now.year - 1, now.month, now.day),
      _Period.thisYear => DateTime(now.year),
    };
    return observations.where((observation) {
      if (_species != null && observation.species != _species) return false;
      if (from == null) return true;
      final date = observation.date;
      return date != null && !date.isBefore(from);
    }).toList();
  }

  Widget _buildFilters(Color primary) {
    Widget chip(String label, bool selected, VoidCallback onSelected) => Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: primary,
        labelStyle: TextStyle(color: selected ? Colors.white : null),
        showCheckmark: false,
        onSelected: (_) => setState(onSelected),
      ),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        chip(translations.allTime, _period == _Period.allTime, () => _period = _Period.allTime),
        chip(translations.last12Months, _period == _Period.last12Months, () => _period = _Period.last12Months),
        chip(translations.thisYear, _period == _Period.thisYear, () => _period = _Period.thisYear),
        const SizedBox(width: 12.0),
        chip(translations.allSpecies, _species == null, () => _species = null),
        for (final (index, species) in translations.speciesDefaultValues.indexed)
          chip(_labels.getSpeciesLabel(index, species), _species == species, () => _species = species),
      ]),
    );
  }

  Widget _buildTotals(ObservationStats stats, Color primary) {
    Widget total(String label, int value) => Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
          child: Column(children: [
            Text(NumberFormat.decimalPattern().format(value), style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: primary)),
            const SizedBox(height: 2.0),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.0)),
          ]),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(children: [
        total(translations.observationsCount, stats.total),
        total(translations.sitesCount, stats.sites),
        if (_canSeeAll) total(translations.observersCount, stats.observers),
        total(translations.withPikasCount, stats.withPikas),
      ]),
    );
  }

  Widget _card(String title, Widget chart) => Card(
    margin: const EdgeInsets.symmetric(vertical: 6.0),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ThemedSubTitle(title, type: ThemeGroupType.POM),
          SizedBox(height: 220.0, child: chart),
        ],
      ),
    ),
  );

  // One labeled bar per month; labels that would overlap are skipped
  Widget _buildPerMonth(ObservationStats stats, Color color) {
    final format = DateFormat.yMMM();
    final months = [for (final entry in stats.perMonth) MapEntry(format.format(entry.key), entry.value)];
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(majorGridLines: MajorGridLines(width: 0), labelIntersectAction: AxisLabelIntersectAction.hide),
      primaryYAxis: _countAxis(months),
      tooltipBehavior: TooltipBehavior(enable: true, format: 'point.x: point.y'),
      series: [
        ColumnSeries<MapEntry<String, int>, String>(
          dataSource: months,
          xValueMapper: (entry, _) => entry.key,
          yValueMapper: (entry, _) => entry.value,
          color: color,
          name: translations.observationsCount,
        ),
      ],
    );
  }

  // Whole numbers only, about five steps
  NumericAxis _countAxis(List<MapEntry<String, int>> entries) {
    final most = entries.fold(0, (most, entry) => entry.value > most ? entry.value : most);
    return NumericAxis(minimum: 0, interval: (most / 5).ceilToDouble().clamp(1, double.infinity), decimalPlaces: 0);
  }

  Widget _buildSpecies(ObservationStats stats, List<Color> colors) {
    final entries = _ordered(stats.species, translations.speciesDefaultValues, _labels.getSpeciesLabel);
    return SfCircularChart(
      legend: const Legend(isVisible: true, position: LegendPosition.right, overflowMode: LegendItemOverflowMode.wrap),
      palette: colors,
      series: [
        DoughnutSeries<MapEntry<String, int>, String>(
          dataSource: entries,
          xValueMapper: (entry, _) => entry.key,
          yValueMapper: (entry, _) => entry.value,
          dataLabelSettings: const DataLabelSettings(isVisible: true),
        ),
      ],
    );
  }

  Widget _buildColumns(List<MapEntry<String, int>> entries, Color color) => SfCartesianChart(
    primaryXAxis: const CategoryAxis(majorGridLines: MajorGridLines(width: 0), labelIntersectAction: AxisLabelIntersectAction.hide),
    primaryYAxis: _countAxis(entries),
    series: [
      ColumnSeries<MapEntry<String, int>, String>(
        dataSource: entries,
        xValueMapper: (entry, _) => entry.key,
        yValueMapper: (entry, _) => entry.value,
        color: color,
        dataLabelSettings: const DataLabelSettings(isVisible: true),
      ),
    ],
  );

  Widget _buildBars(List<MapEntry<String, int>> entries, Color color) => SfCartesianChart(
    primaryXAxis: const CategoryAxis(majorGridLines: MajorGridLines(width: 0), labelsExtent: 120, maximumLabelWidth: 120),
    primaryYAxis: _countAxis(entries),
    series: [
      BarSeries<MapEntry<String, int>, String>(
        // Bars draw bottom up, so reverse to put the first entry on top
        dataSource: entries.reversed.toList(),
        xValueMapper: (entry, _) => entry.key,
        yValueMapper: (entry, _) => entry.value,
        color: color,
        dataLabelSettings: const DataLabelSettings(isVisible: true),
      ),
    ],
  );

  // Round bands (250 m or 1,000 ft) from the lowest to the highest observation, empty bands included
  List<MapEntry<String, int>> _elevationBins(ObservationStats stats, bool isMetric) {
    final band = isMetric ? 250 : 1000;
    final counts = <int, int>{};
    for (final meters in stats.elevationsInMeters) {
      final value = isMetric ? meters : metersToFeet(meters);
      final bin = (value / band).floor() * band;
      counts[bin] = (counts[bin] ?? 0) + 1;
    }
    final format = NumberFormat.decimalPattern();
    final low = counts.keys.reduce((a, b) => a < b ? a : b);
    final high = counts.keys.reduce((a, b) => a > b ? a : b);
    return [
      for (var bin = low; bin <= high; bin += band)
        MapEntry("${format.format(bin)}–${format.format(bin + band)}", counts[bin] ?? 0),
    ];
  }

  // The form's own choices first, in the form's order, then anything typed in, most common first
  List<MapEntry<String, int>> _ordered(Map<String, int> counts, List<String> defaults, String Function(int, String) label) {
    final entries = <MapEntry<String, int>>[];
    for (final (index, value) in defaults.indexed) {
      final count = counts[value];
      if (count != null) entries.add(MapEntry(label(index, value), count));
    }
    final others = counts.entries.where((entry) => !defaults.contains(entry.key));
    return [...entries, ..._byCount(Map.fromEntries(others))];
  }

  List<MapEntry<String, int>> _byCount(Map<String, int> counts) =>
      counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
}
