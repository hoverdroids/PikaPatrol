// ignore_for_file: depend_on_referenced_packages
import 'dart:io';
import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:material_themes_widgets/forms/form_fields.dart';
import 'package:material_themes_widgets/fundamental/icons.dart';
import 'package:material_themes_widgets/fundamental/texts.dart';
import 'package:material_themes_widgets/utils/validators.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:material_themes_widgets/utils/ui_utils.dart';
import '../l10n/translations.dart';
import 'dart:developer' as developer;

class AudioRecorderDialog extends StatefulWidget {
  final LocalFileSystem localFileSystem;

  const AudioRecorderDialog({super.key, localFileSystem}) : localFileSystem = localFileSystem ?? const LocalFileSystem();

  @override
  AudioRecorderDialogState createState() => AudioRecorderDialogState();
}

class AudioRecorderDialogState extends State<AudioRecorderDialog> {

  final _formKey = GlobalKey<FormState>();
  final AudioRecorder _recorder = AudioRecorder();
  RecordState _recordingStatus = RecordState.stop;
  // True once recording has started at least once, so there is something to save
  bool _hasRecording = false;
  String? _tempPath;
  Directory? _directory;
  String? recordingName;

  @override
  void initState() {
    _initAsync();
    super.initState();
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
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
                 if (_recordingStatus == RecordState.record) ... [
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
                  hintText: Provider.of<Translations>(context).recordingNameHint,
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
                        child: ThemedTitle(Provider.of<Translations>(context).cancel, type: ThemeGroupType.MOM),
                        onPressed: () {
                          _quitWithoutSaving();
                        },
                      ),
                      if (_hasRecording) ... [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              // padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
                              backgroundColor: context.watch<MaterialThemesManager>().colorPalette().primary,
                              shape: const StadiumBorder(),
                            ),
                            child: ThemedTitle(Provider.of<Translations>(context).save, type: ThemeGroupType.MOP),
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
    _directory = await getApplicationDocumentsDirectory();

    if (_directory != null) {
      var audioExtension = "m4a";
      final tempPath = '${_directory?.path}/tempAudioRecording.$audioExtension';

      //Delete the last temp recording if it exists - no reason to keep these around
      try {
        final file = File(tempPath);
        await file.delete();
      } catch (e) {
        developer.log(e.toString());
      }

      _tempPath = tempPath;
    }
  }

  void _pause() async {
    if (_recordingStatus == RecordState.record) {
      await _recorder.pause();
    }
    _setRecordingStatus(RecordState.pause);
  }

  void _record() async {
    var tempPath = _tempPath;
    if (tempPath == null) return;

    if (_recordingStatus == RecordState.pause) {
      await _recorder.resume();
    } else {
      // hasPermission() shows the system permission dialog when needed
      if (!await _recorder.hasPermission()) return;
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: tempPath);
    }
    _hasRecording = true;
    _setRecordingStatus(RecordState.record);
  }

  void _quitWithoutSaving() async {
    if (_recordingStatus != RecordState.stop) {
      await _recorder.stop();
    }
    _setRecordingStatus(RecordState.stop);

    if (mounted) Navigator.pop(context, "");
  }

  void _save() async {
    String? resultPath = await _recorder.stop();
    _setRecordingStatus(RecordState.stop);

    final name = recordingName;
    if (resultPath == null || name == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    try {
      // Each recording gets its own folder, so a name used before never replaces an earlier
      // recording (Android) or makes the save fail (iPhone). Characters a file name can't hold
      // become "_". The name shown in the app stays what the volunteer typed. GitHub #31.
      final ext = path.extension(resultPath);
      final folder = Directory(path.join(path.dirname(resultPath), 'recordings', '${DateTime.now().millisecondsSinceEpoch}'));
      await folder.create(recursive: true);
      final safeName = name.trim().replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_');
      final newPath = path.join(folder.path, '${safeName.isEmpty ? 'recording' : safeName}$ext');

      // Copy rather than rename: the temp file is replaced on the next recording either way
      await File(resultPath).copy(newPath);

      if (mounted) Navigator.pop(context, newPath);
    } catch (e) {
      developer.log("Could not save recording: $e");
      if (mounted) {
        showToast(Provider.of<Translations>(context, listen: false).couldNotSaveRecording);
        Navigator.pop(context);
      }
    }
  }

  void _setRecordingStatus(RecordState recordingStatus) {
    if (mounted) {
      setState(() { _recordingStatus = recordingStatus; });
    }
  }
}