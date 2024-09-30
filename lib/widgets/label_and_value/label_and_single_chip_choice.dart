// ignore_for_file: non_constant_identifier_names, depend_on_referenced_packages
import 'package:chips_choice/chips_choice.dart';
import 'package:flutter/material.dart';
import 'package:material_themes_widgets/defaults/dimens.dart';
import 'package:material_themes_widgets/dialogs/text_entry_dialog.dart';
import 'package:material_themes_widgets/fundamental/icons.dart';
import 'package:material_themes_widgets/fundamental/texts.dart';
import 'package:material_themes_manager/material_themes_manager.dart';

class LabelAndSingleChipChoice extends StatelessWidget {

  final String _title;
  final bool _isEditMode;
  final String _selectedValue;
  final List<String> _values;
  final Function(String value) _onSelectedValueChangedCallback;
  final String Function(int index, String value)? _getLabelForSelectedValue;

  final bool canAddNewValues;
  final String? addNewValueDialogTitle;
  final String? addNewValueDialogDescription;
  final Function(String value)? onAddNewValueCallback;
  final String cancelButtonText;
  final String okButtonText;

  const LabelAndSingleChipChoice(
    this._title,
    this._isEditMode,
    this._selectedValue,
    this._values,
    this._onSelectedValueChangedCallback,
    this._getLabelForSelectedValue,
    {
      super.key,
      this.canAddNewValues = false,
      this.addNewValueDialogTitle,
      this.addNewValueDialogDescription,
      this.onAddNewValueCallback,
      this.cancelButtonText = "Cancel",
      this.okButtonText = "OK"
    }
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      smallTransparentDivider,
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ThemedSubTitle(_title, type: ThemeGroupType.POM),
          if (_isEditMode && canAddNewValues)...[
            ThemedIconButton(Icons.add, onPressedCallback: () => _openAddValueDialog(context))
          ]
        ],
      ),
      ChipsChoice<String>.single(
        padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
        value: _selectedValue,
        onChanged: (value) => {
          if (_isEditMode) {
            _onSelectedValueChangedCallback(value)
          }
        },
        choiceItems: C2Choice.listFrom<String, String>(
          source: _values,
          value: (i, v) => v,
          label: (i, v) => _getLabelForSelectedValue != null ? _getLabelForSelectedValue(i, v) : v,
          tooltip: (i, v) => v,
        ),
      )
    ],
  );

  void _openAddValueDialog(BuildContext context) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) => TextEntryDialog(
        title: addNewValueDialogTitle,
        description: addNewValueDialogDescription,
        cancelButtonText: cancelButtonText,
        okButtonText: okButtonText,
      ),
      barrierDismissible: false
    ).then((value) => onAddNewValueCallback?.call(value));
  }

}