import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:material_themes_widgets/fundamental/icons.dart';
import 'package:material_themes_widgets/fundamental/texts.dart';
import 'package:material_themes_widgets/utils/ui_utils.dart';
import 'package:provider/provider.dart';

import '../l10n/translations.dart';
import '../model/storage_file.dart';
import '../services/firebase_database_service.dart';
import '../services/firebase_observations_service.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/scan_progress.dart';
import '../widgets/storage_file_thumbnail.dart';

// Admin-only cleanup: photos and recordings in Storage that no observation uses and that
// Correlate files could not match to one, shown in a grid to check and delete. A plain GridView
// is used because Syncfusion has no media grid; SfDataGrid is a table of rows.
class UnusedFilesScreen extends StatefulWidget {
  const UnusedFilesScreen({super.key});

  @override
  State<UnusedFilesScreen> createState() => _UnusedFilesScreenState();
}

class _UnusedFilesScreenState extends State<UnusedFilesScreen> {

  late Translations translations;
  late final FirebaseObservationsService _service =
      Provider.of<FirebaseDatabaseService>(context, listen: false).observationsService;

  bool _isLoading = true;
  bool _isDeleting = false;
  bool _hasError = false;
  int _scanDone = 0;
  int _scanTotal = 0;
  List<StorageFile> _files = [];
  int _observationCount = 0;
  int _totalFileCount = 0;
  final Set<StorageFile> _selected = {};

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
        _files = scan.unused;
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
    final allSelected = _files.isNotEmpty && _selected.length == _files.length;

    return Scaffold(
      backgroundColor: themes.getTheme(ThemeGroupType.MOM).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(translations.unusedFiles),
        actions: [
          if (!_isLoading && !_isDeleting && _files.isNotEmpty) ...[
            IconButton(
              icon: Icon(allSelected ? Icons.deselect : Icons.select_all),
              tooltip: translations.selectAll,
              onPressed: () => setState(() {
                allSelected ? _selected.clear() : _selected.addAll(_files);
              }),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: translations.deleteSelected,
              onPressed: _selected.isEmpty ? null : _confirmAndDeleteSelected,
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isDeleting) return const Center(child: CircularProgressIndicator());

    if (_isLoading) {
      return ScanProgress(
        translations.checkingFiles.replaceAll('%done%', '$_scanDone').replaceAll('%total%', '$_scanTotal'),
        value: _scanTotal == 0 ? null : _scanDone / _scanTotal,
      );
    }

    if (_hasError) {
      return _buildMessage(translations.couldNotFindUnusedFiles, showRetry: true);
    }

    final selectedBytes = _selected.fold<int>(0, (sum, file) => sum + file.sizeBytes);
    final totalBytes = _files.fold<int>(0, (sum, file) => sum + file.sizeBytes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ThemedBody(
                translations.unusedFilesDescription
                    .replaceAll('%observations%', '$_observationCount')
                    .replaceAll('%files%', '$_totalFileCount'),
                type: ThemeGroupType.MOM,
              ),
              const SizedBox(height: 8.0),
              ThemedSubTitle(
                _selected.isEmpty
                    ? "${_files.length} ${translations.unusedFiles.toLowerCase()}, ${formatFileSize(totalBytes)}"
                    : translations.unusedFilesSelected
                        .replaceAll('%count%', '${_selected.length}')
                        .replaceAll('%size%', formatFileSize(selectedBytes)),
                type: ThemeGroupType.POM,
              ),
            ],
          ),
        ),
        Expanded(
          child: _files.isEmpty
              ? _buildMessage(translations.noUnusedFiles)
              : RefreshIndicator(
                  onRefresh: _scan,
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 160.0,
                      mainAxisSpacing: 8.0,
                      crossAxisSpacing: 8.0,
                    ),
                    itemCount: _files.length,
                    itemBuilder: (context, index) => _buildTile(_files[index]),
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

  Widget _buildTile(StorageFile file) {
    final isSelected = _selected.contains(file);
    return ClipRRect(
      key: ValueKey(file.path),
      borderRadius: BorderRadius.circular(10.0),
      child: Stack(
        fit: StackFit.expand,
        children: [
          StorageFileThumbnail(file, downloadUrl: _service.downloadUrl),
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: isSelected ? Colors.red : Colors.transparent, width: 4.0),
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: ThemedOverlayIconButton(
              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
              onPressedCallback: () => setState(() {
                isSelected ? _selected.remove(file) : _selected.add(file);
              }),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: IgnorePointer(
              child: Container(
                color: Colors.black54,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                child: Text(
                  "${file.created == null ? "" : "${file.created!.toLocal().toString().substring(0, 10)}  "}${formatFileSize(file.sizeBytes)}",
                  style: const TextStyle(color: Colors.white, fontSize: 11.0),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndDeleteSelected() async {
    final confirmed = await showConfirmDialog(
      context,
      title: translations.deleteUnusedFilesDialogTitle.replaceAll('%count%', '${_selected.length}'),
      description: translations.deleteUnusedFilesDialogDescription,
      confirmLabel: translations.delete,
      cancelLabel: translations.cancel,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isDeleting = true);
    final failed = await _service.deleteStorageFiles(_selected.toList());
    if (!mounted) return;

    if (failed.isNotEmpty) showToast(translations.someFilesNotDeleted);
    final deleted = _selected.difference(failed.toSet());
    setState(() {
      _files.removeWhere(deleted.contains);
      _totalFileCount -= deleted.length;
      _selected
        ..clear()
        ..addAll(failed);
      _isDeleting = false;
    });
  }
}
