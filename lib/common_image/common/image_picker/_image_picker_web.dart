@JS()
library image_saver;

// ignore:avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'dart:typed_data';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/widgets.dart';
import 'package:js/js.dart';
import 'package:url_launcher/url_launcher.dart';

class ImageSaver {
  ImageSaver._();

  static Future<String> save(String name, Uint8List fileData) async {
    XFile xFile = XFile.fromData(fileData, name: name);
    xFile.saveTo('');
    return name;
  }
}

Future<Uint8List> pickImage(BuildContext context) async {
  final Completer<Uint8List> completer = Completer<Uint8List>();
  final InputElement input = document.createElement('input') as InputElement;

  input
    ..type = 'file'
    ..accept = 'image/*';
  input.onChange.listen((Event e) async {
    final List<File> files = input.files!;
    final FileReader reader = FileReader();
    reader.readAsArrayBuffer(files[0]);
    reader.onError
        .listen((ProgressEvent error) => completer.completeError(error));
    await reader.onLoad.first;
    completer.complete(reader.result as Uint8List?);
  });
  input.click();
  return completer.future;
}
