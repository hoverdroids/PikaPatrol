import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:material_themes_widgets/fundamental/texts.dart';
import 'package:provider/provider.dart';

import '../l10n/translations.dart';
import '../services/firebase_database_service.dart';
import '../model/storage_scan.dart';
import '../services/firebase_observations_service.dart';
import '../utils/date_time_utils.dart';
import '../widgets/scan_progress.dart';

// Shared by the admin Correlate files and Unused files screens: both read the same Storage scan,
// which is kept in memory and only redone when the admin pulls down to scan again.
mixin StorageScanScreenMixin<T extends StatefulWidget> on State<T> {

  late Translations translations;
  late final FirebaseObservationsService storageService =
      Provider.of<FirebaseDatabaseService>(context, listen: false).observationsService;

  StorageScan? scan;
  bool isScanning = true;
  bool isWorking = false;
  bool hasScanError = false;
  int _scanDone = 0;
  int _scanTotal = 0;

  // Called after each scan so the screen can reset its selection
  void onScanned();

  @override
  void initState() {
    super.initState();
    loadScan();
  }

  Future<void> loadScan({bool rescan = false}) async {
    setState(() {
      isScanning = true;
      hasScanError = false;
      _scanDone = 0;
      _scanTotal = 0;
    });
    try {
      final result = await storageService.scanStorage(rescan: rescan, onProgress: (done, total) {
        if (mounted) setState(() { _scanDone = done; _scanTotal = total; });
      });
      if (!mounted) return;
      setState(() {
        scan = result;
        isScanning = false;
        onScanned();
      });
    } on FirebaseException {
      if (!mounted) return;
      setState(() {
        hasScanError = true;
        isScanning = false;
      });
    }
  }

  // The progress, error or busy view, or null when the screen's own content should show
  Widget? buildScanState() {
    if (isWorking) {
      return Center(child: CircularProgressIndicator(color: context.watch<MaterialThemesManager>().colorPalette().primary));
    }
    if (isScanning) {
      return ScanProgress(
        translations.checkingFiles.replaceAll('%done%', '$_scanDone').replaceAll('%total%', '$_scanTotal'),
        value: _scanTotal == 0 ? null : _scanDone / _scanTotal,
      );
    }
    if (hasScanError || scan == null) {
      return buildScanMessage(translations.couldNotFindUnusedFiles, showRetry: true);
    }
    return null;
  }

  Widget buildScanHeader(String description, List<Widget> selectionButtons, String summary) {
    final current = scan!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ThemedBody(
            description
                .replaceAll('%observations%', '${current.observationCount}')
                .replaceAll('%files%', '${current.totalFileCount}'),
            type: ThemeGroupType.MOM,
          ),
          const SizedBox(height: 4.0),
          ThemedBody(
            translations.scannedAgo.replaceAll('%time%', formatShortDuration(DateTime.now().difference(current.scannedAt))),
            type: ThemeGroupType.MOM,
          ),
          const SizedBox(height: 8.0),
          ThemedSubTitle(summary, type: ThemeGroupType.POM),
          Wrap(spacing: 8.0, children: selectionButtons),
        ],
      ),
    );
  }

  Widget buildScanMessage(String message, {bool showRetry = false}) => Center(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ThemedTitle(message, type: ThemeGroupType.MOM),
          if (showRetry) ...[
            const SizedBox(height: 16.0),
            IconButton(icon: const Icon(Icons.refresh), onPressed: () => loadScan(rescan: true)),
          ],
        ],
      ),
    ),
  );

  // Pull down to scan again. Also works when the list is short or empty.
  Widget buildRefreshable(Widget scrollable) => RefreshIndicator(
    color: context.watch<MaterialThemesManager>().colorPalette().primary,
    onRefresh: () => loadScan(rescan: true),
    child: scrollable,
  );
}
