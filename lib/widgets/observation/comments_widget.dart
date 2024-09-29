// ignore_for_file: non_constant_identifier_names, depend_on_referenced_packages
import 'package:flutter/cupertino.dart';
import 'package:material_themes_widgets/defaults/dimens.dart';
import 'package:material_themes_widgets/forms/form_fields.dart';
import 'package:material_themes_widgets/fundamental/texts.dart';
import 'package:material_themes_manager/material_themes_manager.dart';

class CommentsWidget extends StatelessWidget {

  final String _title;
  final bool _isEditMode;
  final String? _comments;
  final Function(String) _onCommentsChangedCallback;
  final String _hintText;

  const CommentsWidget(
    this._title,
    this._isEditMode,
    this._comments,
    this._onCommentsChangedCallback,
    this._hintText,
    {super.key}
  );

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (boolVal) { return true; },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          smallTransparentDivider,
          ThemedSubTitle(_title, type: ThemeGroupType.POM),
          miniTransparentDivider,
          if(_isEditMode) ... [
            ThemedEditableLabelValue(
              showLabel: false,
              text: _comments ?? "",
              textType: ThemeGroupType.POM,
              hintText: _hintText,
              //hintTextType: hintTextType,
              //hintTextEmphasis: hintTextEmphasis,
              //backgroundType: textFieldBackgroundType,
              onStringChangedCallback: (value) => _onCommentsChangedCallback(value),
              //validator: validator
            )
          ] else ... [
            SizedBox(
              height: 120.0,
              child: SingleChildScrollView(
                child: ThemedBody(
                  _comments,
                  type: ThemeGroupType.MOM,
                ),
              ),
            )
          ]
        ],
      ),
    );
  }
}