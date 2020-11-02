import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart';

//Each time this is built, it will upload the files listed in fileUrls and show the progress of each file. So, make sure that
//it is only displayed when files are ready to be uploaded - otherwise, it'll be a large number of uploads (and cost) for no reason.
class FirebaseFileUploader extends StatefulWidget {

  final List<String> filePaths;//can be local or already stored on Firebase
  final Function filesUploadedCallback;

  FirebaseFileUploader(this.filePaths, this.filesUploadedCallback);

  _FirebaseFileUploaderState createState() => _FirebaseFileUploaderState();
}

class _FirebaseFileUploaderState extends State<FirebaseFileUploader> {

  final FirebaseStorage _storage = FirebaseStorage(storageBucket: 'gs://pikajoe-97c5c.appspot.com');
  var lastIndexUploaded = 0;

  StorageUploadTask _storageUploadTask;

  @override
  Widget build(BuildContext context) {

    if (_storageUploadTask == null && widget.filePaths != null && widget.filePaths.isNotEmpty && lastIndexUploaded < widget.filePaths.length) {
      _storageUploadTask = widget.filePaths == null || widget.filePaths.isEmpty
          ? null
          : _storage.ref().child("images/${basename(widget.filePaths[lastIndexUploaded])}").putFile(File(widget.filePaths[lastIndexUploaded]));
      print("Upload with StreamBuilder:${basename(widget.filePaths[lastIndexUploaded])}");
      lastIndexUploaded = lastIndexUploaded + 1;
    }

    if (_storageUploadTask != null) {

      return StreamBuilder<StorageTaskEvent>(
        stream: _storageUploadTask.events,
        builder: (context, snapshot) {
          var event = snapshot?.data?.snapshot;

          double progressPercent = event != null
              ? event.bytesTransferred / event.totalByteCount
              : 0;

          /*if(_storageUploadTask.isComplete && widget.filesUploadedCallback != null) {
            //setState(() {
              _storageUploadTask = null;
            //});
          }*/

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if(_storageUploadTask.isComplete) ... [

                ] else
                  ... [
                    LinearProgressIndicator(value: progressPercent),
                    Text(
                      '${(progressPercent * 100).toStringAsFixed(2)} % ',
                      style: TextStyle(fontSize: 50),
                    ),
                  ]
              ],
            ),
          );
        },
      );
    } else {
      print("Upload with StreamBuilder :( paths:${widget.filePaths.toString()}");
      return Container(
      );
    }
  }
}