import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:material_themes_widgets/forms/loading.dart';
import 'package:material_themes_widgets/fundamental/icons.dart';
import 'package:material_themes_widgets/fundamental/texts.dart';
import 'package:material_themes_widgets/utils/ui_utils.dart';
import 'package:provider/provider.dart';

import '../l10n/translations.dart';
import '../model/storage_file.dart';
import '../primitives/overlay_mode.dart';
import '../services/firebase_database_service.dart';
import '../widgets/universal_image.dart';

// Admin-only cleanup: photos and recordings in Storage that no observation uses, shown in a grid
// to check and delete. A plain GridView is used because Syncfusion has no media grid; SfDataGrid
// is a table of rows.
class UnusedFilesScreen extends StatefulWidget {
  const UnusedFilesScreen({super.key});

  @override
  State<UnusedFilesScreen> createState() => _UnusedFilesScreenState();
}

class _UnusedFilesScreenState extends State<UnusedFilesScreen> {

  late Translations translations;

  bool _isLoading = true;
  bool _hasError = false;
  List<StorageFile> _files = [];
  int _observationCount = 0;
  int _totalFileCount = 0;
  final Set<StorageFile> _selected = {};

  // Download URLs are fetched once per file, only for tiles that are shown
  final Map<String, Future<String>> _downloadUrls = {};

  final AudioPlayer _audioPlayer = AudioPlayer();
  StorageFile? _playingFile;

  @override
  void initState() {
    super.initState();
    _findUnusedFiles();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _findUnusedFiles() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final service = Provider.of<FirebaseDatabaseService>(context, listen: false).observationsService;
      final result = await service.findUnusedFiles();
      if (!mounted) return;
      setState(() {
        _files = result.unused;
        _observationCount = result.observationCount;
        _totalFileCount = result.totalFileCount;
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

  Future<String> _downloadUrl(StorageFile file) =>
      _downloadUrls.putIfAbsent(file.ref.fullPath, () => file.ref.getDownloadURL());

  String _formatSize(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) return "${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB";
    if (bytes >= 1024 * 1024) return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
    return "${(bytes / 1024).toStringAsFixed(0)} KB";
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
          if (_files.isNotEmpty) ...[
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
    if (_isLoading) return const Loading();

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
                    ? "${_files.length} ${translations.unusedFiles.toLowerCase()}, ${_formatSize(totalBytes)}"
                    : translations.unusedFilesSelected
                        .replaceAll('%count%', '${_selected.length}')
                        .replaceAll('%size%', _formatSize(selectedBytes)),
                type: ThemeGroupType.POM,
              ),
            ],
          ),
        ),
        Expanded(
          child: _files.isEmpty
              ? _buildMessage(translations.noUnusedFiles)
              : RefreshIndicator(
                  onRefresh: _findUnusedFiles,
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
            IconButton(icon: const Icon(Icons.refresh), onPressed: _findUnusedFiles),
          ],
        ],
      ),
    ),
  );

  Widget _buildTile(StorageFile file) {
    final isSelected = _selected.contains(file);
    return GestureDetector(
      onTap: () => file.isImage ? _showImage(file) : _toggleAudio(file),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.0),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (file.isImage)
              FutureBuilder<String>(
                future: _downloadUrl(file),
                builder: (context, snapshot) => snapshot.hasData
                    ? UniversalImage(snapshot.data!, overlayMode: OverlayMode.never, height: double.infinity)
                    : Container(color: Colors.black12),
              )
            else
              Container(
                color: Colors.teal.shade800,
                child: Icon(
                  _playingFile == file ? Icons.stop : Icons.play_arrow,
                  color: Colors.white,
                  size: 48.0,
                ),
              ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: isSelected ? Colors.red : Colors.transparent, width: 4.0),
                borderRadius: BorderRadius.circular(10.0),
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
              child: Container(
                color: Colors.black54,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                child: Text(
                  "${file.created == null ? "" : "${file.created!.toLocal().toString().substring(0, 10)}  "}${_formatSize(file.sizeBytes)}",
                  style: const TextStyle(color: Colors.white, fontSize: 11.0),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showImage(StorageFile file) async {
    final url = await _downloadUrl(file);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: InteractiveViewer(
          child: UniversalImage(url, overlayMode: OverlayMode.never, boxFit: BoxFit.contain, height: 500.0),
        ),
      ),
    );
  }

  Future<void> _toggleAudio(StorageFile file) async {
    if (_playingFile == file) {
      await _audioPlayer.stop();
      if (mounted) setState(() => _playingFile = null);
      return;
    }
    setState(() => _playingFile = file);
    try {
      await _audioPlayer.setUrl(await _downloadUrl(file));
      await _audioPlayer.play();
    } catch (_) {
      // Unplayable file; nothing to show beyond stopping
    }
    if (mounted && _playingFile == file) setState(() => _playingFile = null);
  }

  Future<void> _confirmAndDeleteSelected() async {
    final service = Provider.of<FirebaseDatabaseService>(context, listen: false).observationsService;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(translations.deleteUnusedFilesDialogTitle.replaceAll('%count%', '${_selected.length}')),
        content: Text(translations.deleteUnusedFilesDialogDescription),
        actions: [
          TextButton(child: Text(translations.cancel), onPressed: () => Navigator.pop(context, false)),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              backgroundColor: Colors.red,
              shape: const StadiumBorder(),
            ),
            child: ThemedTitle(translations.delete, type: ThemeGroupType.MOP),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await _audioPlayer.stop();
    setState(() {
      _playingFile = null;
      _isLoading = true;
    });

    final failed = await service.deleteStorageFiles(_selected.toList());
    if (!mounted) return;

    if (failed.isNotEmpty) showToast(translations.someFilesNotDeleted);
    final deleted = _selected.difference(failed.toSet());
    setState(() {
      _files.removeWhere(deleted.contains);
      _totalFileCount -= deleted.length;
      _selected
        ..clear()
        ..addAll(failed);
      _isLoading = false;
    });
  }
}
