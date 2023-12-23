import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:media_editor/common_image/custom_image.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

Future<CustomImage?> pickImage(BuildContext context) async {
  final List<AssetEntity>? result = await AssetPicker.pickAssets(
    context,
    pickerConfig: const AssetPickerConfig(
      maxAssets: 1,
      pathThumbnailSize: ThumbnailSize.square(84),
      gridCount: 3,
      pageSize: 300,
      requestType: RequestType.image,
      textDelegate: EnglishAssetPickerTextDelegate(),
    ),
  );
  if (result != null) {
    if (result.first.title == null) {
      throw Exception('Cannot get image name');
    }
    final bytes = await result.first.originBytes;
    if (bytes == null) {
      throw Exception('Cannot get image bytes');
    }
    final CustomImage image = CustomImage(
      name: result.first.title!,
      data: bytes,
    );

    return image;
  }
  return null;
}

class ImageSaver {
  const ImageSaver._();

  static Future<String?> save(String name, Uint8List fileData) async {
    final String title = '${DateTime.now().millisecondsSinceEpoch}_$name';
    final AssetEntity? imageEntity = await PhotoManager.editor.saveImage(
      fileData,
      title: title,
    );
    final File? file = await imageEntity?.file;
    return file?.path;
  }
}
