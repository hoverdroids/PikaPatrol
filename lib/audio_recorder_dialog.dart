import 'dart:io';

import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:material_themes_widgets/forms/form_fields.dart';
import 'package:material_themes_widgets/fundamental/icons.dart';
import 'package:material_themes_widgets/fundamental/texts.dart';
import 'package:material_themes_widgets/utils/validators.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class AudioRecorderDialog extends StatefulWidget {
  final LocalFileSystem localFileSystem;

  AudioRecorderDialog({localFileSystem}) : this.localFileSystem = localFileSystem ?? LocalFileSystem();
  _AudioRecorderDialogState createState() => _AudioRecorderDialogState();
}

class _AudioRecorderDialogState extends State<AudioRecorderDialog> {

  final _formKey = GlobalKey<FormState>();
  FlutterAudioRecorder _recorder;
  RecordingStatus _recordingStatus;
  Directory _directory;
  String recordingName;

  @override
  void initState() {
    _initAsync();
    super.initState();
  }

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
                _quitWithoutSaving();
              },
              child: CircleAvatar(
                child: ThemedIcon(Icons.close, type: ThemeGroupType.MOP),
                backgroundColor: context.watch<MaterialThemesManager>().colorPalette().primary,
              ),
            ),
          ),
          Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (_recordingStatus == RecordingStatus.Recording) ... [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: ThemedIconButton(Icons.pause, onPressedCallback: () => setState(() => {
                      _pause()
                    }))
                  )
                ]
                else ... [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: ThemedIconButton(Icons.mic, onPressedCallback: () => _record())
                  )
                ],
                ThemedEditableLabelValue(
                  showLabel: false,
                  hintText: "Recording Name",
                  validator:  (value) => nonEmptyValidator(value, "Name"),
                  onStringChangedCallback: (value) => setState(() => { recordingName = value }),
                ),
                if (_recordingStatus != RecordingStatus.Initialized) ... [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: RaisedButton(
                      shape: StadiumBorder(),
                      color: context.watch<MaterialThemesManager>().colorPalette().primary,
                      child: ThemedTitle("Save", type: ThemeGroupType.MOP),
                      onPressed: () {
                        if (_formKey.currentState.validate()) {
                          _formKey.currentState.save();

                          //There is a valid file name, so save the recording and close the dialog
                          _save();
                        } else {
                          //There is not a valid file name. Since only pause/play are shown, don't stop because
                          //it's possible for the user to click save, not have a file name, and continue recording.
                          _pause();
                        }
                      },
                    ),
                  )
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _initAsync() async {
    _directory = await getApplicationDocumentsDirectory();
    final tempPath = '${_directory.path}/tempAudioRecording';

    //Delete the last temp recording if it exists - no reason to keep these around
    try {
      final file = File(tempPath);
      await file.delete();
    } catch (e) {
    }

    _recorder = FlutterAudioRecorder(tempPath, audioFormat: AudioFormat.AAC); // or AudioFormat.WAV
    await _recorder.initialized;
    var recording = await _recorder.current(channel: 0);
    setState(() { _recordingStatus = recording?.status; });
  }

  void _pause() async {
    await _recorder.pause();

    var recording = await _recorder.current(channel: 0);
    setState(() { _recordingStatus = recording?.status; });
  }

  void _record() async {
    _recordingStatus == RecordingStatus.Paused
        ? await _recorder.resume()
        : await _recorder.start();

    var recording = await _recorder.current(channel: 0);
    setState(() { _recordingStatus = recording?.status; });
  }

  void _quitWithoutSaving() async {
    if (_recordingStatus != RecordingStatus.Stopped) {
      await _recorder.stop();
    }

    var recording = await _recorder.current(channel: 0);
    setState(() { _recordingStatus = recording?.status; });

    Navigator.pop(context, "");
  }

  void _save() async {
    var result = await _recorder.stop();
    var recording = await _recorder.current(channel: 0);
    setState(() { _recordingStatus = recording?.status; });

    String ext = path.extension(result.path);
    String dir = path.dirname(result.path);
    String newPath = path.join(dir, '$recordingName.$ext');

    File file = File(result.path);
    await file.rename(newPath);

    Navigator.pop(context, newPath);
  }
}