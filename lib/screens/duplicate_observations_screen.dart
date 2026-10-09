import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:material_themes_widgets/fundamental/texts.dart';
import 'package:material_themes_widgets/utils/ui_utils.dart';
import 'package:provider/provider.dart';

import '../l10n/translations.dart';
import '../model/observation.dart';
import '../model/observation_view_model.dart';
import '../primitives/overlay_mode.dart';
import '../services/duplicate_observation_finder.dart';
import '../services/firebase_database_service.dart';
import '../services/firebase_observations_service.dart';
import '../services/observations_service.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/universal_image.dart';
import 'observation_screen.dart';

// Admin-only: observations saved to the server more than once (see DuplicateObservationFinder).
// Each group shows its copies side by side; the admin picks the copy to keep, checks the groups
// to merge, and merges them together. A ListView of cards is used because each group is a small
// comparison, which Syncfusion's table-style SfDataGrid doesn't fit.
class DuplicateObservationsScreen extends StatefulWidget {
  const DuplicateObservationsScreen({super.key});

  @override
  State<DuplicateObservationsScreen> createState() => _DuplicateObservationsScreenState();
}

class _DuplicateObservationsScreenState extends State<DuplicateObservationsScreen> {

  late Translations translations;
  late final FirebaseObservationsService _service =
      Provider.of<FirebaseDatabaseService>(context, listen: false).observationsService;

  List<DuplicateGroup> _groups = [];
  final Set<DuplicateGroup> _selected = {};
  bool _isLoading = true;
  bool _isWorking = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final groups = await _service.findDuplicates(refresh: refresh);
      if (!mounted) return;
      setState(() {
        _groups = groups;
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
    final primary = themes.colorPalette().primary;

    return Scaffold(
      backgroundColor: themes.getTheme(ThemeGroupType.MOM).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(translations.duplicateObservations),
        actions: [
          if (!_isLoading && !_isWorking && _groups.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.merge),
              tooltip: translations.mergeSelected,
              onPressed: _selected.isEmpty ? null : _confirmAndMerge,
            ),
        ],
      ),
      body: _isLoading || _isWorking
          ? Center(child: CircularProgressIndicator(color: primary))
          : _hasError
              ? _buildMessage(translations.couldNotLoadObservations)
              : _buildContent(primary),
    );
  }

  Widget _buildMessage(String message) => RefreshIndicator(
    onRefresh: () => _load(refresh: true),
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32.0),
      children: [Center(child: ThemedTitle(message, type: ThemeGroupType.MOM))],
    ),
  );

  Widget _buildContent(Color primary) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ThemedBody(translations.duplicateObservationsDescription, type: ThemeGroupType.MOM),
            const SizedBox(height: 8.0),
            ThemedSubTitle("${_selected.length} / ${_groups.length}", type: ThemeGroupType.POM),
            Wrap(spacing: 8.0, children: [
              TextButton.icon(
                icon: const Icon(Icons.select_all),
                label: Text(translations.selectAll),
                onPressed: _groups.isEmpty ? null : () => setState(() => _selected.addAll(_groups)),
              ),
              TextButton.icon(
                icon: const Icon(Icons.deselect),
                label: Text(translations.clearSelection),
                onPressed: _selected.isEmpty ? null : () => setState(_selected.clear),
              ),
            ]),
          ],
        ),
      ),
      Expanded(
        child: _groups.isEmpty
            ? _buildMessage(translations.noDuplicatesFound)
            : RefreshIndicator(
                color: primary,
                onRefresh: () => _load(refresh: true),
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: _groups.length,
                  itemBuilder: (context, index) => _buildGroup(_groups[index], primary),
                ),
              ),
      ),
    ],
  );

  Widget _buildGroup(DuplicateGroup group, Color primary) {
    final isSelected = _selected.contains(group);
    final first = group.keep;
    final date = first.date == null ? "" : DateFormat.yMMMd(Localizations.localeOf(context).toString()).add_jm().format(first.date!.toLocal());

    return Card(
      key: ObjectKey(group),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(color: isSelected ? primary : Colors.transparent, width: 3.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(first.location ?? "", style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text("$date  ·  ${translations.copiesCount.replaceAll('%count%', '${group.observations.length}')}",
                          style: const TextStyle(fontSize: 12.0)),
                    ],
                  ),
                ),
                Checkbox(
                  value: isSelected,
                  activeColor: primary,
                  onChanged: (value) => setState(() {
                    value == true ? _selected.add(group) : _selected.remove(group);
                  }),
                ),
              ],
            ),
            for (var copy in group.observations) _buildCopy(group, copy, primary),
          ],
        ),
      ),
    );
  }

  Widget _buildCopy(DuplicateGroup group, Observation copy, Color primary) {
    final cover = copy.imageUrls?.isNotEmpty == true ? copy.imageUrls!.first : "";
    final locale = Localizations.localeOf(context).toString();
    final saved = copy.dateUpdatedInGoogleSheets == null
        ? ""
        : DateFormat.yMMMd(locale).add_jm().format(copy.dateUpdatedInGoogleSheets!.toLocal());

    return InkWell(
      onTap: () => setState(() => group.keep = copy),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Radio<Observation>(
              value: copy,
              groupValue: group.keep,
              activeColor: primary,
              onChanged: (value) => setState(() => group.keep = copy),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(6.0),
              child: SizedBox(
                width: 56.0,
                height: 56.0,
                child: UniversalImage(cover, overlayMode: OverlayMode.never, height: double.infinity),
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (copy == group.keep)
                    Text(translations.keepThisCopy, style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
                  Text("📷 ${copy.imageUrls?.length ?? 0}  🎙 ${copy.audioUrls?.length ?? 0}  ·  ${copy.species}",
                      style: const TextStyle(fontSize: 12.0)),
                  if (saved.isNotEmpty) Text("☁ $saved", style: const TextStyle(fontSize: 12.0)),
                  Text(copy.uid ?? "", style: const TextStyle(fontSize: 10.0, color: Colors.grey)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () => _openObservation(copy),
            ),
          ],
        ),
      ),
    );
  }

  void _openObservation(Observation observation) {
    final viewModel = ObservationViewModel(observation.copy(), translations);
    Navigator.push(context, MaterialPageRoute(builder: (_) => ObservationScreen(viewModel)));
  }

  Future<void> _confirmAndMerge() async {
    final observationsService = Provider.of<ObservationsService>(context, listen: false);
    final confirmed = await showConfirmDialog(
      context,
      title: translations.mergeDuplicatesDialogTitle.replaceAll('%count%', '${_selected.length}'),
      description: translations.mergeDuplicatesDialogDescription,
      confirmLabel: translations.mergeSelected,
      cancelLabel: translations.cancel,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isWorking = true);
    final selected = _selected.toList();
    final failures = await observationsService.mergeDuplicates(selected);
    if (!mounted) return;

    showToast(failures == 0
        ? translations.duplicatesMerged.replaceAll('%count%', '${selected.length}')
        : translations.someDuplicatesNotMerged.replaceAll('%count%', '$failures'));

    setState(() {
      // Merged groups already left the cached list
      _selected.removeWhere((group) => !_groups.contains(group));
      _isWorking = false;
    });
  }
}
