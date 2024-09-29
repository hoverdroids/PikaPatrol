// ignore_for_file: non_constant_identifier_names, depend_on_referenced_packages
import 'package:chips_choice/chips_choice.dart';
import 'package:flutter/cupertino.dart';
import 'package:material_themes_widgets/defaults/dimens.dart';
import 'package:material_themes_widgets/fundamental/texts.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:material_themes_widgets/utils/collection_utils.dart';

class SharedWithProjectsWidget extends StatelessWidget {

  final String _title;
  final bool _isEditMode;

  final List<String> _approvedOrganizations;
  final List<String>? _sharedWithProjects;
  final List<String>? _notSharedWithProjects;
  final Function(List<String>, List<String>) _onSharedWithProjectsChangedCallback;

  const SharedWithProjectsWidget(
    this._title,
    this._isEditMode,
    this._approvedOrganizations,
    this._sharedWithProjects,
    this._notSharedWithProjects,
    this._onSharedWithProjectsChangedCallback,
    {super.key}
  );

  @override
  Widget build(BuildContext context) {

    //TODO - this needs some rework from the top down
    //For example, save the default approved, sharedWith, etc and then allow dynamic project update from Firebase sheets being added
    var sharedWithProjects = _sharedWithProjects ?? [];
    var notSharedWithProjects = _notSharedWithProjects ?? [];

    for (var approvedOrganization in _approvedOrganizations) {
      if (!sharedWithProjects.contains(approvedOrganization) && !notSharedWithProjects.contains(approvedOrganization)) {
        notSharedWithProjects.add(approvedOrganization);
      }
    }

    sharedWithProjects = sharedWithProjects.toTrimmedUniqueList().sortList();
    notSharedWithProjects = notSharedWithProjects.toTrimmedUniqueList().sortList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        smallTransparentDivider,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ThemedSubTitle(_title, type: ThemeGroupType.POM),
            // if (_isEditMode)...[
            //   ThemedIconButton(Icons.add, onPressedCallback: () => _openSharedWithProjectsDialog())
            // ]
          ],
        ),
        if(sharedWithProjects.isNotEmpty || notSharedWithProjects.isNotEmpty) ... [
          ChipsChoice<String>.multiple(
            padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
            value: sharedWithProjects,
            onChanged: (updatedSharedWithProjects) => {
              if (_isEditMode) {
                _updateSharedWithProjects(updatedSharedWithProjects)
              }
            },
            choiceItems: C2Choice.listFrom<String, String>(
              source: _approvedOrganizations,
              value: (i, v) => v,
              label: (i, v) => v,
              tooltip: (i, v) => v,
            ),
          )
        ]
      ],
    );
  }

  _updateSharedWithProjects(List<String> updatedSharedWithProjects) {
    final approvedSet = _approvedOrganizations.toSet();
    final selectedSet = updatedSharedWithProjects.toSet();
    final updatedNotSharedWithProjects = List<String>.from(approvedSet.difference(selectedSet));

    _onSharedWithProjectsChangedCallback(updatedSharedWithProjects, updatedNotSharedWithProjects);
  }
  
  /*void _openSharedWithProjectsDialog() {
    if (!mounted) return;

    showDialog(
        context: context,
        builder: (BuildContext context) => TextEntryDialog(
            title: translations.addAnotherProjectDialogTitle,
            description: translations.addAnotherProjectDialogDescription
        ),
        barrierDismissible: false
    ).then((value) => {
      setState(() {
        if (value != null && (value as String).isNotEmpty) {
          var sharedWithProjects = widget.observation.sharedWithProjects ?? <String>[];
          sharedWithProjects.addAll(value.split(","));
          sharedWithProjects = sharedWithProjects.map((string) => string.replaceAllMapped(RegExp(r'^\s+|\s+$'), (match) => "")).toSet().toList();
          widget.observation.sharedWithProjects = sharedWithProjects;
        }
      })
    });
  }*/
  
}