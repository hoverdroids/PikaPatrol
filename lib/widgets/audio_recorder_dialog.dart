// ignore_for_file: depend_on_referenced_packages
import 'dart:io';
import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_recorder3/flutter_audio_recorder3.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:material_themes_widgets/forms/form_fields.dart';
import 'package:material_themes_widgets/fundamental/icons.dart';
import 'package:material_themes_widgets/fundamental/texts.dart';
import 'package:material_themes_widgets/utils/validators.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;

class AudioRecorderDialog extends StatefulWidget {
  final LocalFileSystem localFileSystem;

  const AudioRecorderDialog({super.key, localFileSystem}) : localFileSystem = localFileSystem ?? const LocalFileSystem();

  @override
  AudioRecorderDialogState createState() => AudioRecorderDialogState();
}

class AudioRecorderDialogState extends State<AudioRecorderDialog> {

  final _formKey = GlobalKey<FormState>();
  late FlutterAudioRecorder3 _recorder;
  RecordingStatus _recordingStatus = RecordingStatus.Unset;
  Directory? _directory;
  String? recordingName;

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
        clipBehavior: Clip.none,
        children: <Widget>[
          //context.watch<MaterialThemesManager>().getBackgroundGradient(BackgroundGradientType.PRIMARY),
          Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                 if (_recordingStatus == RecordingStatus.Recording) ... [
                  Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ThemedIconButton(Icons.pause, onPressedCallback: () => setState(() => _pause()
                      ))
                  )
                ]
                else ... [
                  Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ThemedIconButton(Icons.mic, onPressedCallback: () => _record())
                  )
                ],
                ThemedEditableLabelValue(
                  showLabel: false,
                  hintText: "Recording Name",
                  validator:  (value) => nonEmptyValidator(value, "Name", true),
                  onStringChangedCallback: (value) => setState(() => recordingName = value ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 16.0, 0, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          // padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
                          backgroundColor: context.watch<MaterialThemesManager>().colorPalette().lightBg,
                          shape: const StadiumBorder(),
                        ),
                        child: ThemedTitle("Cancel", type: ThemeGroupType.MOM),
                        onPressed: () {
                          _quitWithoutSaving();
                        },
                      ),
                      if (_recordingStatus == RecordingStatus.Recording || _recordingStatus == RecordingStatus.Paused || _recordingStatus == RecordingStatus.Stopped) ... [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              // padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
                              backgroundColor: context.watch<MaterialThemesManager>().colorPalette().primary,
                              shape: const StadiumBorder(),
                            ),
                            child: ThemedTitle("Save", type: ThemeGroupType.MOP),
                            onPressed: () {
                              if (_formKey.currentState?.validate() == true) {
                                _formKey.currentState?.save();

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
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _initAsync() async {
    _directory = await getTemporaryDirectory();//blu getApplicationDocumentsDirectory();

    if (_directory != null) {
      final tempPath = '${_directory?.path}/tempAudioRecording';

      //Delete the last temp recording if it exists - no reason to keep these around
      try {
        final file = File('$tempPath.aac');
        await file.delete();
      } catch (e) {
        developer.log(e.toString());
      }

      _recorder = FlutterAudioRecorder3(tempPath, audioFormat: AudioFormat.AAC); // or AudioFormat.WAV
      await _recorder.initialized;
      var recording = await _recorder.current(channel: 0);
      setRecordingStatus(recording);
    }
  }

  void _pause() async {
    await _recorder.pause();

    var recording = await _recorder.current(channel: 0);
    setRecordingStatus(recording);
  }

  void _record() async {
    _recordingStatus == RecordingStatus.Paused
        ? await _recorder.resume()
        : await _recorder.start();

    var recording = await _recorder.current(channel: 0);
    setRecordingStatus(recording);
  }

  void _quitWithoutSaving() async {
    if (_recordingStatus != RecordingStatus.Stopped) {
      await _recorder.stop();
    }

    var recording = await _recorder.current(channel: 0);
    setRecordingStatus(recording);

    if (mounted) Navigator.pop(context, "");
  }

  void _save() async {
    var result = await _recorder.stop();
    var recording = await _recorder.current(channel: 0);
    setRecordingStatus(recording);

    String? resultPath = result?.path;
    if (resultPath != null && recordingName != null) {
      String ext = path.extension(resultPath).substring(1);//Need to string dot from .extension
      String dir = path.dirname(resultPath);
      String newPath = path.join(dir, '$recordingName.$ext');

      developer.log("NewPath:$newPath ext:$ext dir:$dir");

      File file = File(resultPath);
      await file.rename(newPath);

      if (mounted) Navigator.pop(context, newPath);
    } else {
      if (mounted) Navigator.pop(context);
    }
  }

  void setRecordingStatus(Recording? recording) {
    var recordingStatus = recording?.status;
    if (recordingStatus != null) {
      setState(() { _recordingStatus = recordingStatus; });
    }
  }
}