import 'package:flutter/material.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:material_themes_widgets/utils/ui_utils.dart';
import 'package:provider/provider.dart';

import '../l10n/translations.dart';
import '../model/observation.dart';
import '../model/observation_view_model.dart';
import '../services/observations_service.dart';
import '../services/storage_file_correlator.dart';
import '../utils/date_time_utils.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/storage_file_thumbnail.dart';
import 'observation_screen.dart';
import 'storage_scan_screen_mixin.dart';

// Admin-only repair of broken photo and recording links. Each row pairs a stored file with the
// observation it most likely belongs to and how sure the match is (see StorageFileCorrelator);
// the admin can pick another observation, check the rows that look right, and fix them together.
// A ListView is used because each row is a small side-by-side comparison, which Syncfusion's
// table-style SfDataGrid doesn't fit.
class CorrelateFilesScreen extends StatefulWidget {
  const CorrelateFilesScreen({super.key});

  @override
  State<CorrelateFilesScreen> createState() => _CorrelateFilesScreenState();
}

class _CorrelateFilesScreenState extends State<CorrelateFilesScreen> with StorageScanScreenMixin {

  final Set<FileFix> _selected = {};

  List<FileFix> get _fixes => scan?.fixes ?? const [];

  @override
  void onScanned() => _selected.clear();

  @override
  Widget build(BuildContext context) {
    translations = Provider.of<Translations>(context);
    final themes = context.watch<MaterialThemesManager>();

    return Scaffold(
      backgroundColor: themes.getTheme(ThemeGroupType.MOM).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(translations.correlateFiles),
        actions: [
          if (!isScanning && !isWorking && _fixes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.link),
              tooltip: translations.fixSelectedLinks,
              onPressed: _selected.isEmpty ? null : _confirmAndFixSelected,
            ),
        ],
      ),
      body: buildScanState() ?? _buildContent(),
    );
  }

  Widget _buildContent() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      buildScanHeader(
        translations.correlateFilesDescription,
        [
          TextButton.icon(
            icon: const Icon(Icons.select_all),
            label: Text(translations.selectAll),
            onPressed: _fixes.isEmpty ? null : () => setState(() => _selected.addAll(_fixes)),
          ),
          TextButton.icon(
            icon: const Icon(Icons.verified),
            label: Text(translations.selectAbove90),
            onPressed: _fixes.isEmpty ? null : () => setState(() {
              _selected.addAll(_fixes.where((fix) => fix.certainty >= 0.9));
            }),
          ),
          TextButton.icon(
            icon: const Icon(Icons.deselect),
            label: Text(translations.clearSelection),
            onPressed: _selected.isEmpty ? null : () => setState(_selected.clear),
          ),
        ],
        "${_selected.length} / ${_fixes.length}",
      ),
      Expanded(
        child: buildRefreshable(
          _fixes.isEmpty
              ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: [buildScanMessage(translations.noBrokenLinksFound)])
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: _fixes.length,
                  itemBuilder: (context, index) => _buildRow(_fixes[index]),
                ),
        ),
      ),
    ],
  );

  Widget _buildRow(FileFix fix) {
    final isSelected = _selected.contains(fix);
    final primary = context.watch<MaterialThemesManager>().colorPalette().primary;

    return Card(
      key: ObjectKey(fix),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(color: isSelected ? primary : Colors.transparent, width: 3.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: SizedBox(
                width: 96.0,
                height: 96.0,
                child: StorageFileThumbnail(fix.file, key: ValueKey(fix.file.path), downloadUrl: storageService.downloadUrl),
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              // Tap to choose another observation, or to open one and compare
              child: InkWell(
                onTap: () => _chooseObservation(fix),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildCertainty(fix.certainty),
                        if (fix.candidates.length > 1) ...[
                          const SizedBox(width: 6.0),
                          Icon(Icons.swap_horiz, size: 18.0, color: primary),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    ..._buildObservationSummary(fix.observation),
                    const SizedBox(height: 4.0),
                    for (var signal in fix.match.signals)
                      Text("• ${_describe(signal)}", style: const TextStyle(fontSize: 12.0)),
                  ],
                ),
              ),
            ),
            Checkbox(
              value: isSelected,
              activeColor: primary,
              onChanged: (value) => setState(() {
                value == true ? _selected.add(fix) : _selected.remove(fix);
              }),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildObservationSummary(Observation observation) {
    final title = observation.location?.isNotEmpty == true ? observation.location! : (observation.name ?? "");
    final date = observation.date?.toLocal().toString().substring(0, 16) ?? "";
    final photos = observation.imageUrls?.length ?? 0;
    final recordings = observation.audioUrls?.length ?? 0;
    return [
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
      if (observation.name?.isNotEmpty == true && observation.location?.isNotEmpty == true)
        Text(observation.name!, maxLines: 1, overflow: TextOverflow.ellipsis),
      Text("$date  ·  📷 $photos  🎙 $recordings", style: const TextStyle(fontSize: 12.0)),
    ];
  }

  // Teal when nearly sure, orange in the middle, grey when it's a long shot
  Widget _buildCertainty(double certainty) {
    final primary = context.watch<MaterialThemesManager>().colorPalette().primary;
    final color = certainty >= 0.9 ? primary : certainty >= 0.5 ? Colors.orange.shade800 : Colors.grey.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10.0)),
      child: Text(
        "${(certainty * 100).round()}%",
        style: const TextStyle(color: Colors.white, fontSize: 12.0, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _describe(MatchSignal signal) {
    final time = signal.apart == null ? "" : formatShortDuration(signal.apart!);
    return switch (signal.kind) {
      MatchSignalKind.linkExpired => translations.fixReasonRefreshLink,
      MatchSignalKind.sameName => translations.fixReasonSameName,
      MatchSignalKind.uploadedWithLinkedFile => translations.matchUploadedWithLinkedFile.replaceAll('%time%', time),
      MatchSignalKind.madeNearObservationStart => translations.matchMadeNearObservationStart.replaceAll('%time%', time),
      MatchSignalKind.uploadedNearSave => translations.matchUploadedNearSave.replaceAll('%time%', time),
      MatchSignalKind.uploadedAfterObservationDate => translations.matchUploadedAfterObservationDate.replaceAll('%time%', time),
      MatchSignalKind.observationHasBrokenLink => translations.matchObservationHasBrokenLink,
      MatchSignalKind.closeRunnerUp => translations.matchCloseRunnerUp,
    };
  }

  // Lists every candidate observation with its certainty; tap one to use it, or the open icon
  // to look at it first
  Future<void> _chooseObservation(FileFix fix) async {
    final chosen = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16.0),
          children: [
            Text(translations.otherPossibleObservations, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8.0),
            for (var i = 0; i < fix.candidates.length; i++)
              ListTile(
                selected: i == fix.chosen,
                leading: _buildCertainty(fix.candidates[i].certainty),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._buildObservationSummary(fix.candidates[i].observation),
                    for (var signal in fix.candidates[i].signals)
                      Text("• ${_describe(signal)}", style: const TextStyle(fontSize: 12.0)),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () => _openObservation(fix.candidates[i].observation),
                ),
                onTap: () => Navigator.pop(context, i),
              ),
          ],
        ),
      ),
    );
    if (chosen != null && mounted) {
      setState(() => fix.chosen = chosen);
      storageService.saveScanCache();
    }
  }

  void _openObservation(Observation observation) {
    final viewModel = ObservationViewModel(observation.copy(), translations);
    Navigator.push(context, MaterialPageRoute(builder: (_) => ObservationScreen(viewModel)));
  }

  Future<void> _confirmAndFixSelected() async {
    final observationsService = Provider.of<ObservationsService>(context, listen: false);
    final primary = context.read<MaterialThemesManager>().colorPalette().primary;
    final confirmed = await showConfirmDialog(
      context,
      title: translations.fixLinksDialogTitle.replaceAll('%count%', '${_selected.length}'),
      description: translations.fixLinksDialogDescription,
      confirmLabel: translations.fixSelectedLinks,
      cancelLabel: translations.cancel,
      confirmColor: primary,
    );
    if (!confirmed || !mounted) return;

    setState(() => isWorking = true);
    final selected = _selected.toList();
    final observationCount = selected.map((fix) => fix.observation).toSet().length;
    final failures = await observationsService.applyFileFixes(scan!, selected);
    if (!mounted) return;

    showToast(failures == 0
        ? translations.linksFixed.replaceAll('%count%', '$observationCount')
        : translations.someLinksNotFixed.replaceAll('%count%', '$failures'));

    // The cached scan already dropped the fixed files, so there's no need to scan again
    setState(() {
      _selected.removeWhere((fix) => !_fixes.contains(fix));
      isWorking = false;
    });
  }
}
