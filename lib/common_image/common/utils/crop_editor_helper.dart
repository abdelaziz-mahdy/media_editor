//import 'dart:typed_data';
import 'dart:isolate';
import 'dart:ui';

// import 'package:isolate/load_balancer.dart';
// import 'package:isolate/isolate_runner.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/foundation.dart';
// ignore: implementation_imports
import 'package:http_client_helper/http_client_helper.dart';
import 'package:image/image.dart';
import 'package:image_editor/image_editor.dart';

// final Future<LoadBalancer> loadBalancer =
//     LoadBalancer.create(1, IsolateRunner.spawn);

enum ImageType { gif, jpg }

class EditImageInfo {
  EditImageInfo(
    this.data,
    this.imageType,
  );

  final Uint8List? data;
  final ImageType imageType;
}

Future<EditImageInfo> cropImageDataWithDartLibrary(
    {required ExtendedImageEditorState state,
    String imageEncoding = 'jpg'}) async {
  print('dart library start cropping');

  ///crop rect base on raw image
  Rect cropRect = state.getCropRect()!;

  print('getCropRect : $cropRect');

  // in web, we can't get rawImageData due to .
  // using following code to get imageCodec without download it.
  // final Uri resolved = Uri.base.resolve(key.url);
  // // This API only exists in the web engine implementation and is not
  // // contained in the analyzer summary for Flutter.
  // return ui.webOnlyInstantiateImageCodecFromUrl(
  //     resolved); //

  final Uint8List data = kIsWeb &&
          state.widget.extendedImageState.imageWidget.image
              is ExtendedNetworkImageProvider
      ? await _loadNetwork(state.widget.extendedImageState.imageWidget.image
          as ExtendedNetworkImageProvider)

      ///toByteData is not work on web
      ///https://github.com/flutter/flutter/issues/44908
      // (await state.image.toByteData(format: ui.ImageByteFormat.png))
      //     .buffer
      //     .asUint8List()
      : state.rawImageData;

  if (data == state.rawImageData &&
      state.widget.extendedImageState.imageProvider is ExtendedResizeImage) {
    final ImmutableBuffer buffer =
        await ImmutableBuffer.fromUint8List(state.rawImageData);
    final ImageDescriptor descriptor = await ImageDescriptor.encoded(buffer);
    final double widthRatio = descriptor.width / state.image!.width;
    final double heightRatio = descriptor.height / state.image!.height;
    cropRect = Rect.fromLTRB(
      cropRect.left * widthRatio,
      cropRect.top * heightRatio,
      cropRect.right * widthRatio,
      cropRect.bottom * heightRatio,
    );
  }

  final EditActionDetails editAction = state.editAction!;

  final DateTime time1 = DateTime.now();

  //Decode source to Animation. It can holds multi frame.
  Image? src;
  //LoadBalancer lb;
  if (kIsWeb) {
    src = decodeImage(data);
  } else {
    src = await compute(decodeImage, data);
  }
  if (src != null) {
    //handle every frame.
    src.frames = src.frames.map((Image image) {
      final DateTime time2 = DateTime.now();
      //clear orientation
      image = bakeOrientation(image);

      if (editAction.needCrop) {
        image = copyCrop(
          image,
          x: cropRect.left.toInt(),
          y: cropRect.top.toInt(),
          width: cropRect.width.toInt(),
          height: cropRect.height.toInt(),
        );
      }

      if (editAction.needFlip) {
        late FlipDirection mode;
        if (editAction.flipY && editAction.flipX) {
          mode = FlipDirection.both;
        } else if (editAction.flipY) {
          mode = FlipDirection.horizontal;
        } else if (editAction.flipX) {
          mode = FlipDirection.vertical;
        }
        image = flip(image, direction: mode);
      }

      if (editAction.hasRotateAngle) {
        image = copyRotate(image, angle: editAction.rotateAngle);
      }
      final DateTime time3 = DateTime.now();
      print('${time3.difference(time2)} : crop/flip/rotate');
      return image;
    }).toList();
    if (src.frames.length == 1) {}
  }

  /// you can encode your image
  ///
  /// it costs much time and blocks ui.
  //var fileData = encodeJpg(src);

  /// it will not block ui with using isolate.
  //var fileData = await compute(encodeJpg, src);
  //var fileData = await isolateEncodeImage(src);
  assert(src != null);
  List<int>? fileData;
  print('start encode');
  final DateTime time4 = DateTime.now();
  final bool onlyOneFrame = src!.numFrames == 1;

  // //If there's only one frame, encode it to jpg.
  // if (kIsWeb) {
  //   fileData =
  //       onlyOneFrame ? encodeJpg(Image.from(src.frames.first)) : encodeGif(src);
  // } else {
  //   //fileData = await lb.run<List<int>, Image>(encodeJpg, src);
  //   fileData = (onlyOneFrame
  //       ? await compute(encodeJpg, Image.from(src.frames.first))
  //       : await compute(encodeGif, src));
  // }
  Image imageToEncode = onlyOneFrame ? Image.from(src.frames.first) : src;

  try {
    fileData = await encodeImage(imageToEncode, imageEncoding);
  } catch (e) {
    // Handle the error (e.g., unsupported image type)
    print('Error encoding image: $e');
  }
  final DateTime time5 = DateTime.now();
  print('${time5.difference(time4)} : encode to ${imageEncoding}');
  print('${time5.difference(time1)} : total time');
  return EditImageInfo(
    Uint8List.fromList(fileData!),
    onlyOneFrame ? ImageType.jpg : ImageType.gif,
  );
}

/// it may be failed, due to Cross-domain
Future<Uint8List> _loadNetwork(ExtendedNetworkImageProvider key) async {
  try {
    final Response? response = await HttpClientHelper.get(Uri.parse(key.url),
        headers: key.headers,
        timeLimit: key.timeLimit,
        timeRetry: key.timeRetry,
        retries: key.retries,
        cancelToken: key.cancelToken);
    return response!.bodyBytes;
  } on OperationCanceledError catch (_) {
    print('User cancel request ${key.url}.');
    return Future<Uint8List>.error(
        StateError('User cancel request ${key.url}.'));
  } catch (e) {
    return Future<Uint8List>.error(StateError('failed load ${key.url}. \n $e'));
  }
}

typedef ImageEncoder = Future<Uint8List> Function(Image image);

Future<Uint8List> encodeImage(Image image, String imageType) async {
  switch (imageType.toLowerCase()) {
    case 'jpg':
      return compute(encodeJpg, image);
    case 'png':
      return compute(encodePng, image);
    case 'gif':
      return compute(encodeGif, image);
    case 'bmp':
      return compute(encodeBmp, image);
    case 'tga':
      return compute(encodeTga, image);
    case 'pvr':
      // Assuming you have a function to encode PVR.
      // If not, you'll need to implement or find a suitable library.
      return compute(encodePvr, image);
    case 'ico':
      return compute(encodeIco, image);
    // Add other cases for different formats as needed
    default:
      throw UnsupportedError('Unsupported image type');
  }
}
