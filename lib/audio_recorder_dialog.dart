import 'package:flutter/material.dart';
import 'package:material_themes_widgets/forms/form_fields.dart';
import 'package:material_themes_widgets/fundamental/buttons_media.dart';
import 'package:material_themes_widgets/fundamental/icons.dart';
import 'package:material_themes_widgets/fundamental/texts.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:material_themes_widgets/utils/validators.dart';
import 'package:provider/provider.dart';

class AudioRecorderDialog extends StatefulWidget {
  _AudioRecorderDialogState createState() => _AudioRecorderDialogState();
}

class _AudioRecorderDialogState extends State<AudioRecorderDialog> {

  final _formKey = GlobalKey<FormState>();
  bool _isRecording = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      //contentPadding: EdgeInsets.all(0.0),
      content: Stack(
        overflow: Overflow.visible,
        children: <Widget>[
          //context.watch<MaterialThemesManager>().getBackgroundGradient(BackgroundGradientType.PRIMARY),
          Positioned(
            right: -40.0,
            top: -40.0,
            child: InkResponse(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: CircleAvatar(
                child: ThemedIcon(Icons.close, type: ThemeGroupType.MOP),//Icon(Icons.close, color: Colors.white),
                backgroundColor: context.watch<MaterialThemesManager>().colorPalette().primary,
              ),
            ),
          ),
          Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (_isRecording) ... [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: ThemedIconButton(Icons.pause, onPressedCallback: () => setState(() => { _isRecording = false}))
                    )
                ]
                else ... [
                  Padding(
                      padding: EdgeInsets.all(8.0),
                      child: ThemedIconButton(Icons.mic, onPressedCallback: () => setState(() => { _isRecording = true}))
                  )
                ],
                ThemedEditableLabelValue(
                  showLabel: false,
                  hintText: "Recording Name",
                  validator:  (value) => nonEmptyValidator(value, "Name"),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: RaisedButton(
                    shape: StadiumBorder(),
                    color: context.watch<MaterialThemesManager>().colorPalette().primary,
                    child: ThemedTitle("Save", type: ThemeGroupType.MOP),
                    onPressed: () {
                      if (_formKey.currentState.validate()) {
                        _formKey.currentState.save();
                      }
                    },
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}