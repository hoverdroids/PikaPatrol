import '../utils/media_cache.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../model/storage_file.dart';
import '../primitives/overlay_mode.dart';
import 'universal_image.dart';

// A Storage photo or recording for the admin file tools. Tap a photo to see it full size, or a
// recording to play it. The download URL is only fetched once the tile is built.
class StorageFileThumbnail extends StatefulWidget {
  final StorageFile file;
  final Future<String> Function(String path) downloadUrl;

  const StorageFileThumbnail(this.file, {super.key, required this.downloadUrl});

  @override
  State<StorageFileThumbnail> createState() => _StorageFileThumbnailState();
}

class _StorageFileThumbnailState extends State<StorageFileThumbnail> {

  late final Future<String> _url = widget.downloadUrl(widget.file.path);
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: widget.file.isImage ? _showImage : _toggleAudio,
    child: widget.file.isImage
        ? FutureBuilder<String>(
            future: _url,
            builder: (context, snapshot) => snapshot.hasData
                ? UniversalImage(snapshot.data!, overlayMode: OverlayMode.never, height: double.infinity)
                : Container(color: Colors.black12),
          )
        : Container(
            color: Colors.teal,
            child: Icon(_isPlaying ? Icons.stop : Icons.play_arrow, color: Colors.white, size: 48.0),
          ),
  );

  Future<void> _showImage() async {
    final url = await _url;
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

  Future<void> _toggleAudio() async {
    final player = _audioPlayer ??= AudioPlayer();
    if (_isPlaying) {
      await player.stop();
      if (mounted) setState(() => _isPlaying = false);
      return;
    }
    setState(() => _isPlaying = true);
    try {
      await player.setFilePath((await MediaCache.file(await _url)).path);
      await player.play();
    } catch (_) {
      // Unplayable file; just show it as stopped
    }
    if (mounted) setState(() => _isPlaying = false);
  }
}
