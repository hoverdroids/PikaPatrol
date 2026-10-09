import 'package:flutter/material.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:material_themes_widgets/fundamental/icons.dart';
import 'package:material_themes_widgets/utils/ui_utils.dart';
import 'package:provider/provider.dart';

import '../l10n/translations.dart';
import '../model/storage_file.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/storage_file_thumbnail.dart';
import 'storage_scan_screen_mixin.dart';

// Admin-only cleanup: photos and recordings in Storage that no observation uses and that match
// no observation well, shown in a grid to check and delete. A plain GridView is used because
// Syncfusion has no media grid; SfDataGrid is a table of rows.
class UnusedFilesScreen extends StatefulWidget {
  const UnusedFilesScreen({super.key});

  @override
  State<UnusedFilesScreen> createState() => _UnusedFilesScreenState();
}

class _UnusedFilesScreenState extends State<UnusedFilesScreen> with StorageScanScreenMixin {

  final Set<StorageFile> _selected = {};

  List<StorageFile> get _files => scan?.unused ?? const [];

  @override
  void onScanned() => _selected.clear();

  @override
  Widget build(BuildContext context) {
    translations = Provider.of<Translations>(context);
    final themes = context.watch<MaterialThemesManager>();

    return Scaffold(
      backgroundColor: themes.getTheme(ThemeGroupType.MOM).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(translations.unusedFiles),
        actions: [
          if (!isScanning && !isWorking && _files.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: translations.deleteSelected,
              onPressed: _selected.isEmpty ? null : _confirmAndDeleteSelected,
            ),
        ],
      ),
      body: buildScanState() ?? _buildContent(),
    );
  }

  Widget _buildContent() {
    final selectedBytes = _selected.fold<int>(0, (sum, file) => sum + file.sizeBytes);
    final totalBytes = _files.fold<int>(0, (sum, file) => sum + file.sizeBytes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildScanHeader(
          translations.unusedFilesDescription,
          [
            TextButton.icon(
              icon: const Icon(Icons.select_all),
              label: Text(translations.selectAll),
              onPressed: _files.isEmpty ? null : () => setState(() => _selected.addAll(_files)),
            ),
            TextButton.icon(
              icon: const Icon(Icons.deselect),
              label: Text(translations.clearSelection),
              onPressed: _selected.isEmpty ? null : () => setState(_selected.clear),
            ),
          ],
          _selected.isEmpty
              ? "${_files.length} ${translations.unusedFiles.toLowerCase()}, ${formatFileSize(totalBytes)}"
              : translations.unusedFilesSelected
                  .replaceAll('%count%', '${_selected.length}')
                  .replaceAll('%size%', formatFileSize(selectedBytes)),
        ),
        Expanded(
          child: buildRefreshable(
            _files.isEmpty
                ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: [buildScanMessage(translations.noUnusedFiles)])
                : GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
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

  Widget _buildTile(StorageFile file) {
    final isSelected = _selected.contains(file);
    return ClipRRect(
      key: ValueKey(file.path),
      borderRadius: BorderRadius.circular(10.0),
      child: Stack(
        fit: StackFit.expand,
        children: [
          StorageFileThumbnail(file, downloadUrl: storageService.downloadUrl),
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

    setState(() => isWorking = true);
    final failed = await storageService.deleteStorageFiles(_selected.toList());
    if (!mounted) return;

    if (failed.isNotEmpty) showToast(translations.someFilesNotDeleted);
    final deleted = _selected.difference(failed.toSet());
    scan?.removeDeletedFiles(deleted);
    storageService.saveScanCache();
    setState(() {
      _selected
        ..clear()
        ..addAll(failed);
      isWorking = false;
    });
  }
}
