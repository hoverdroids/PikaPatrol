import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:material_themes_widgets/fundamental/texts.dart';
import 'package:material_themes_widgets/utils/ui_utils.dart';
import 'package:provider/provider.dart';

import '../l10n/translations.dart';
import '../model/observation_view_model.dart';
import '../services/firebase_database_service.dart';
import '../services/firebase_observations_service.dart';
import '../services/observations_service.dart';
import '../services/storage_file_correlator.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/scan_progress.dart';
import '../widgets/storage_file_thumbnail.dart';
import 'observation_screen.dart';

// Admin-only repair of broken photo and recording links. Each row pairs a broken link with the
// stored file most likely to be the right one (see StorageFileCorrelator); the admin checks the
// rows that look right and fixes them together. A ListView is used because each row is a small
// side-by-side comparison, which Syncfusion's table-style SfDataGrid doesn't fit.
class CorrelateFilesScreen extends StatefulWidget {
  const CorrelateFilesScreen({super.key});

  @override
  State<CorrelateFilesScreen> createState() => _CorrelateFilesScreenState();
}

class _CorrelateFilesScreenState extends State<CorrelateFilesScreen> {

  late Translations translations;
  late final FirebaseObservationsService _service =
      Provider.of<FirebaseDatabaseService>(context, listen: false).observationsService;

  bool _isLoading = true;
  bool _isFixing = false;
  bool _hasError = false;
  int _scanDone = 0;
  int _scanTotal = 0;
  List<FileFix> _fixes = [];
  int _observationCount = 0;
  int _totalFileCount = 0;
  final Set<FileFix> _selected = {};

  @override
  void initState() {
    super.initState();
    _scan();
  }

  Future<void> _scan() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _scanDone = 0;
      _scanTotal = 0;
    });
    try {
      final scan = await _service.scanStorage(onProgress: (done, total) {
        if (mounted) setState(() { _scanDone = done; _scanTotal = total; });
      });
      if (!mounted) return;
      setState(() {
        _fixes = scan.fixes;
        _observationCount = scan.observationCount;
        _totalFileCount = scan.totalFileCount;
        _selected.clear();
        _isLoading = false;
      });
    } on FirebaseException {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    translations = Provider.of<Translations>(context);
    final themes = context.watch<MaterialThemesManager>();
    final allSelected = _fixes.isNotEmpty && _selected.length == _fixes.length;
    final isBusy = _isLoading || _isFixing;

    return Scaffold(
      backgroundColor: themes.getTheme(ThemeGroupType.MOM).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(translations.correlateFiles),
        actions: [
          if (!isBusy && _fixes.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.verified),
              tooltip: translations.selectCertain,
              onPressed: () => setState(() {
                _selected.addAll(_fixes.where((fix) => fix.confidence == FileFixConfidence.high));
              }),
            ),
            IconButton(
              icon: Icon(allSelected ? Icons.deselect : Icons.select_all),
              tooltip: translations.selectAll,
              onPressed: () => setState(() {
                allSelected ? _selected.clear() : _selected.addAll(_fixes);
              }),
            ),
            IconButton(
              icon: const Icon(Icons.link),
              tooltip: translations.fixSelectedLinks,
              onPressed: _selected.isEmpty ? null : _confirmAndFixSelected,
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isFixing) return Center(child: CircularProgressIndicator(color: context.watch<MaterialThemesManager>().colorPalette().primary));

    if (_isLoading) {
      return ScanProgress(
        translations.checkingFiles.replaceAll('%done%', '$_scanDone').replaceAll('%total%', '$_scanTotal'),
        value: _scanTotal == 0 ? null : _scanDone / _scanTotal,
      );
    }

    if (_hasError) {
      return _buildMessage(translations.couldNotFindUnusedFiles, showRetry: true);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ThemedBody(
            translations.correlateFilesDescription
                .replaceAll('%observations%', '$_observationCount')
                .replaceAll('%files%', '$_totalFileCount'),
            type: ThemeGroupType.MOM,
          ),
        ),
        Expanded(
          child: _fixes.isEmpty
              ? _buildMessage(translations.noBrokenLinksFound)
              : RefreshIndicator(
                  onRefresh: _scan,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    itemCount: _fixes.length,
                    itemBuilder: (context, index) => _buildRow(_fixes[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildMessage(String message, {bool showRetry = false}) => Center(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ThemedTitle(message, type: ThemeGroupType.MOM),
          if (showRetry) ...[
            const SizedBox(height: 16.0),
            IconButton(icon: const Icon(Icons.refresh), onPressed: _scan),
          ],
        ],
      ),
    ),
  );

  Widget _buildRow(FileFix fix) {
    final isSelected = _selected.contains(fix);
    final observation = fix.observation;
    final date = observation.date?.toLocal().toString().substring(0, 16) ?? "";

    return Card(
      key: ValueKey('${observation.uid}-${fix.file.path}-${fix.brokenUrl}'),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(color: isSelected ? Colors.teal : Colors.transparent, width: 3.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: SizedBox(
                width: 96.0,
                height: 96.0,
                child: StorageFileThumbnail(fix.file, key: ValueKey(fix.file.path), downloadUrl: _service.downloadUrl),
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              // Opens the observation, to compare the file with what's there
              child: InkWell(
                onTap: () => _openObservation(fix),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      observation.location?.isNotEmpty == true ? observation.location! : (observation.name ?? ""),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (observation.name?.isNotEmpty == true && observation.location?.isNotEmpty == true)
                      Text(observation.name!, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(date),
                    const SizedBox(height: 4.0),
                    Text(_reason(fix), style: const TextStyle(fontSize: 12.0)),
                    const SizedBox(height: 4.0),
                    _buildConfidence(fix.confidence),
                  ],
                ),
              ),
            ),
            Checkbox(
              value: isSelected,
              onChanged: (value) => setState(() {
                value == true ? _selected.add(fix) : _selected.remove(fix);
              }),
            ),
          ],
        ),
      ),
    );
  }

  String _reason(FileFix fix) => switch (fix.reason) {
    FileFixReason.refreshLink => translations.fixReasonRefreshLink,
    FileFixReason.sameName => translations.fixReasonSameName,
    FileFixReason.uploadedNearby => translations.fixReasonUploadedNearby.replaceAll('%time%', _formatDuration(fix.timeApart)),
  };

  String _formatDuration(Duration? duration) {
    if (duration == null) return "";
    if (duration.inMinutes < 1) return "${duration.inSeconds} s";
    if (duration.inHours < 1) return "${duration.inMinutes} min";
    return "${duration.inHours} h ${duration.inMinutes % 60} min";
  }

  Widget _buildConfidence(FileFixConfidence confidence) {
    final (label, color) = switch (confidence) {
      FileFixConfidence.high => (translations.fixConfidenceHigh, Colors.teal),
      FileFixConfidence.likely => (translations.fixConfidenceLikely, Colors.orange.shade800),
      FileFixConfidence.possible => (translations.fixConfidencePossible, Colors.grey.shade700),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10.0)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12.0, fontWeight: FontWeight.bold)),
    );
  }

  void _openObservation(FileFix fix) {
    final viewModel = ObservationViewModel(fix.observation.copy(), translations);
    Navigator.push(context, MaterialPageRoute(builder: (_) => ObservationScreen(viewModel)));
  }

  Future<void> _confirmAndFixSelected() async {
    final observationsService = Provider.of<ObservationsService>(context, listen: false);
    final confirmed = await showConfirmDialog(
      context,
      title: translations.fixLinksDialogTitle.replaceAll('%count%', '${_selected.length}'),
      description: translations.fixLinksDialogDescription,
      confirmLabel: translations.fixSelectedLinks,
      cancelLabel: translations.cancel,
      confirmColor: Colors.teal,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isFixing = true);
    final selected = _selected.toList();
    final observationCount = selected.map((fix) => fix.observation.uid).toSet().length;
    final failures = await observationsService.applyFileFixes(selected);
    if (!mounted) return;

    showToast(failures == 0
        ? translations.linksFixed.replaceAll('%count%', '$observationCount')
        : translations.someLinksNotFixed.replaceAll('%count%', '$failures'));

    // Scan again so the list matches what's now stored
    setState(() => _isFixing = false);
    await _scan();
  }
}
