// ignore:avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';

import 'dart:typed_data';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:media_editor/common_image/custom_image.dart';

class ImageSaver {
  ImageSaver._();

  static Future<String> save(String name, Uint8List fileData) async {
    XFile xFile = XFile.fromData(fileData, name: name);
    xFile.saveTo('');
    return name;
  }
}

Future<CustomImage> pickImage(BuildContext context) async {
  FilePickerResult? result = await FilePicker.platform.pickFiles();
  if (result == null) {
    throw Exception('No file selected');
  }

  if (result.files.single.bytes == null) {
    throw Exception('Cannot get image bytes');
  }
  final CustomImage image = CustomImage(
    name: result.files.single.name,
    data: result.files.single.bytes!,
  );
  return image;
}
