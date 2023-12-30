import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:media_editor/image_editor.dart';
import 'package:oktoast/oktoast.dart';

import 'video_editor.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return OKToast(
        position: ToastPosition.bottom,
        child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Flutter Demo',
            theme: ThemeData(
              // This is the theme of your application.
              //
              // TRY THIS: Try running your application with "flutter run". You'll see
              // the application has a purple toolbar. Then, without quitting the app,
              // try changing the seedColor in the colorScheme below to Colors.green
              // and then invoke "hot reload" (save your changes or press the "hot
              // reload" button in a Flutter-supported IDE, or press "r" if you used
              // the command line to start the app).
              //
              // Notice that the counter didn't reset back to zero; the application
              // state is not lost during the reload. To reset the state, use hot
              // restart instead.
              //
              // This works for code too, not just values: Most code changes can be
              // tested with just a hot reload.
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
            home: Scaffold(
              appBar: AppBar(title: const Text('Flutter Media Editor')),
              body: const UploadMediaWidget(),
            )));
  }
}

class UploadMediaWidget extends StatefulWidget {
  const UploadMediaWidget({super.key});

  @override
  State<UploadMediaWidget> createState() => _UploadMediaWidgetState();
}

class _UploadMediaWidgetState extends State<UploadMediaWidget> {
  final allowedVideoExtensions = ['mp4', 'avi', 'mov', 'wmv', 'flv', 'mkv'];
  final allowedImageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
  void _pickVideo({XFile? file}) async {
    FilePickerResult? result = (await FilePicker.platform.pickFiles(
      allowedExtensions: allowedVideoExtensions,
      allowMultiple: false,
      type: FileType.custom,
    ));
    if (result == null) {
      return;
    }
    file = XFile.fromData(result.files.firstOrNull!.bytes!,
        name: result.files.firstOrNull!.name);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (BuildContext context) => VideoEditor(file: file!),
        ),
      );
    }
  }

  void _pickImage({XFile? file}) async {
    FilePickerResult? result = (await FilePicker.platform.pickFiles(
      allowedExtensions: allowedImageExtensions,
      allowMultiple: false,
      type: FileType.custom,
    ));

    if (result == null) {
      return;
    }
    file = XFile.fromData(result.files.firstOrNull!.bytes!,
        name: result.files.firstOrNull!.name);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (BuildContext context) => ImageEditor(file: file!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DropTarget(
        onDragDone: (details) async {
          XFile? file = details.files.firstOrNull;

          if (file != null) {
            String extension = file.name.split('.').last.toLowerCase();

            if (allowedImageExtensions.contains(extension)) {
              // It's an image file
              _pickImage(file: file);
            } else if (allowedVideoExtensions.contains(extension)) {
              // It's a video file
              _pickVideo(file: file);
            } else {
              showToast("Unsupported file type: $extension");
            }
          }
        },
        child: Container(
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.upload_file,
                size: 50,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                "Pick or drop Image or Video here",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickVideo,
                child: const Text("Pick Video From Gallery"),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text("Pick Image From Gallery"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
