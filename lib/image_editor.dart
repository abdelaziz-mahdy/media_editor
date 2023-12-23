import 'dart:async';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:media_editor/common_image/custom_image.dart';
import 'package:oktoast/oktoast.dart';
import 'package:url_launcher/url_launcher.dart';

import 'common_image/common/image_picker/image_picker.dart';
import 'common_image/common/utils/crop_editor_helper.dart';
import 'common_image/common/widget/common_widget.dart';

// THIS editor is from the extended_image package example
// https://pub.dev/packages/extended_image

class ImageEditor extends StatefulWidget {
  const ImageEditor({super.key});

  @override
  _ImageEditorState createState() => _ImageEditorState();
}

class _ImageEditorState extends State<ImageEditor> {
  final GlobalKey<ExtendedImageEditorState> editorKey =
      GlobalKey<ExtendedImageEditorState>();
  final GlobalKey<PopupMenuButtonState<EditorCropLayerPainter>> popupMenuKey =
      GlobalKey<PopupMenuButtonState<EditorCropLayerPainter>>();
  final List<AspectRatioItem> _aspectRatios = <AspectRatioItem>[
    AspectRatioItem(text: 'custom', value: CropAspectRatios.custom),
    AspectRatioItem(text: 'original', value: CropAspectRatios.original),
    AspectRatioItem(text: '1*1', value: CropAspectRatios.ratio1_1),
    AspectRatioItem(text: '4*3', value: CropAspectRatios.ratio4_3),
    AspectRatioItem(text: '3*4', value: CropAspectRatios.ratio3_4),
    AspectRatioItem(text: '16*9', value: CropAspectRatios.ratio16_9),
    AspectRatioItem(text: '9*16', value: CropAspectRatios.ratio9_16)
  ];
  AspectRatioItem? _aspectRatio;
  bool _cropping = false;
  String _imageType = "JPG";
  EditorCropLayerPainter? _cropLayerPainter;
  CustomImage? _memoryImage;

  @override
  void initState() {
    _aspectRatio = _aspectRatios.first;
    _cropLayerPainter = const EditorCropLayerPainter();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _memoryImage == null
            ? null
            : IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    _memoryImage = null;
                  });
                }),
        title: const Text('image editor'),
        actions: <Widget>[
          ImageTypeDropdown(
              currentValue: _imageType,
              onSelected: (value) {
                setState(() {
                  _imageType = value;
                });
              }),
          IconButton(
            icon: const Icon(Icons.done),
            onPressed: () {
              if (kIsWeb) {
                _cropImage(false);
              } else {
                _showCropDialog(context);
              }
            },
          ),
        ],
      ),
      body: Column(children: <Widget>[
        Expanded(
          child: _memoryImage != null
              ? ExtendedImage.memory(
                  _memoryImage!.data,
                  fit: BoxFit.contain,
                  mode: ExtendedImageMode.editor,
                  enableLoadState: true,
                  extendedImageEditorKey: editorKey,
                  initEditorConfigHandler: (ExtendedImageState? state) {
                    return EditorConfig(
                      maxScale: 8.0,
                      cropRectPadding: const EdgeInsets.all(20.0),
                      hitTestSize: 20.0,
                      cropLayerPainter: _cropLayerPainter!,
                      initCropRectType: InitCropRectType.imageRect,
                      cropAspectRatio: _aspectRatio!.value,
                    );
                  },
                  cacheRawData: true,
                )
              : Center(
                  child: DropTarget(
                    onDragDone: (details) async {
                      if (details.files.isNotEmpty) {
                        CustomImage image = CustomImage(
                          name: details.files.first.name,
                          data: await details.files.first.readAsBytes(),
                        );
                        setImage(image);
                      }
                    },
                    child: GestureDetector(
                      onTap: () async {
                        _getImage();
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.upload_file,
                              size: 50,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              "Pick or drop file here",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ]),
      bottomNavigationBar: BottomAppBar(
        //color: Colors.lightBlue,
        shape: const CircularNotchedRectangle(),
        child: ButtonTheme(
          minWidth: 0.0,
          padding: EdgeInsets.zero,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              constraints:
                  BoxConstraints(minWidth: MediaQuery.of(context).size.width),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                // mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  FlatButtonWithIcon(
                    icon: const Icon(Icons.crop),
                    label: const Text(
                      'Crop',
                      style: TextStyle(fontSize: 10.0),
                    ),
                    textColor: Colors.white,
                    onPressed: () {
                      showDialog<void>(
                          context: context,
                          builder: (BuildContext context) {
                            return Column(
                              children: <Widget>[
                                const Expanded(
                                  child: SizedBox(),
                                ),
                                SizedBox(
                                  height: 100,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.all(20.0),
                                    itemBuilder: (_, int index) {
                                      final AspectRatioItem item =
                                          _aspectRatios[index];
                                      return GestureDetector(
                                        child: AspectRatioWidget(
                                          aspectRatio: item.value,
                                          aspectRatioS: item.text,
                                          isSelected: item == _aspectRatio,
                                        ),
                                        onTap: () {
                                          Navigator.pop(context);
                                          setState(() {
                                            _aspectRatio = item;
                                          });
                                        },
                                      );
                                    },
                                    itemCount: _aspectRatios.length,
                                  ),
                                ),
                              ],
                            );
                          });
                    },
                  ),
                  FlatButtonWithIcon(
                    icon: const Icon(Icons.flip),
                    label: const Text(
                      'Flip',
                      style: TextStyle(fontSize: 10.0),
                    ),
                    textColor: Colors.white,
                    onPressed: () {
                      editorKey.currentState!.flip();
                    },
                  ),
                  FlatButtonWithIcon(
                    icon: const Icon(Icons.rotate_left),
                    label: const Text(
                      'Rotate Left',
                      style: TextStyle(fontSize: 8.0),
                    ),
                    textColor: Colors.white,
                    onPressed: () {
                      editorKey.currentState!.rotate(right: false);
                    },
                  ),
                  FlatButtonWithIcon(
                    icon: const Icon(Icons.rotate_right),
                    label: const Text(
                      'Rotate Right',
                      style: TextStyle(fontSize: 8.0),
                    ),
                    textColor: Colors.white,
                    onPressed: () {
                      editorKey.currentState!.rotate(right: true);
                    },
                  ),
                  FlatButtonWithIcon(
                    icon: const Icon(Icons.rounded_corner_sharp),
                    label: PopupMenuButton<EditorCropLayerPainter>(
                      key: popupMenuKey,
                      enabled: false,
                      offset: const Offset(100, -300),
                      initialValue: _cropLayerPainter,
                      itemBuilder: (BuildContext context) {
                        return <PopupMenuEntry<EditorCropLayerPainter>>[
                          const PopupMenuItem<EditorCropLayerPainter>(
                            value: EditorCropLayerPainter(),
                            child: Row(
                              children: <Widget>[
                                Icon(
                                  Icons.rounded_corner_sharp,
                                  color: Colors.blue,
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                Text('Default'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem<EditorCropLayerPainter>(
                            value: CustomEditorCropLayerPainter(),
                            child: Row(
                              children: <Widget>[
                                Icon(
                                  Icons.circle,
                                  color: Colors.blue,
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                Text('Custom'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem<EditorCropLayerPainter>(
                            value: CircleEditorCropLayerPainter(),
                            child: Row(
                              children: <Widget>[
                                Icon(
                                  CupertinoIcons.circle,
                                  color: Colors.blue,
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                Text('Circle'),
                              ],
                            ),
                          ),
                        ];
                      },
                      onSelected: (EditorCropLayerPainter value) {
                        if (_cropLayerPainter != value) {
                          setState(() {
                            if (value is CircleEditorCropLayerPainter) {
                              _aspectRatio = _aspectRatios[2];
                            }
                            _cropLayerPainter = value;
                          });
                        }
                      },
                      child: const Text(
                        'Painter',
                        style: TextStyle(fontSize: 8.0),
                      ),
                    ),
                    textColor: Colors.white,
                    onPressed: () {
                      popupMenuKey.currentState!.showButtonMenu();
                    },
                  ),
                  FlatButtonWithIcon(
                    icon: const Icon(Icons.restore),
                    label: const Text(
                      'Reset',
                      style: TextStyle(fontSize: 10.0),
                    ),
                    textColor: Colors.white,
                    onPressed: () {
                      editorKey.currentState!.reset();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCropDialog(BuildContext context) {
    showDialog<void>(
        context: context,
        builder: (BuildContext content) {
          return Column(
            children: <Widget>[
              Expanded(
                child: Container(),
              ),
              Container(
                  margin: const EdgeInsets.all(20.0),
                  child: Material(
                      child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'select library to crop',
                          style: TextStyle(
                              fontSize: 24.0, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(
                          height: 20.0,
                        ),
                        Text.rich(TextSpan(children: <TextSpan>[
                          TextSpan(
                            children: <TextSpan>[
                              TextSpan(
                                  text: 'Image',
                                  style: const TextStyle(
                                      color: Colors.blue,
                                      decorationStyle:
                                          TextDecorationStyle.solid,
                                      decorationColor: Colors.blue,
                                      decoration: TextDecoration.underline),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      launchUrl(Uri.parse(
                                          'https://github.com/brendan-duncan/image'));
                                    }),
                              const TextSpan(
                                  text:
                                      '(Dart library) for decoding/encoding image formats, and image processing. It\'s stable.')
                            ],
                          ),
                          const TextSpan(text: '\n\n'),
                          TextSpan(
                            children: <TextSpan>[
                              TextSpan(
                                  text: 'ImageEditor',
                                  style: const TextStyle(
                                      color: Colors.blue,
                                      decorationStyle:
                                          TextDecorationStyle.solid,
                                      decorationColor: Colors.blue,
                                      decoration: TextDecoration.underline),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      launchUrl(Uri.parse(
                                          'https://github.com/fluttercandies/flutter_image_editor'));
                                    }),
                              const TextSpan(
                                  text:
                                      '(Native library) support android/ios, crop flip rotate. It\'s faster.')
                            ],
                          )
                        ])),
                        const SizedBox(
                          height: 20.0,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: <Widget>[
                            OutlinedButton(
                              child: const Text(
                                'Dart',
                                style: TextStyle(
                                  color: Colors.blue,
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                                _cropImage(false);
                              },
                            ),
                            OutlinedButton(
                              child: const Text(
                                'Native',
                                style: TextStyle(
                                  color: Colors.blue,
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                                _cropImage(true);
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                  ))),
              Expanded(
                child: Container(),
              )
            ],
          );
        });
  }

  Future<void> _cropImage(bool useNative) async {
    if (_cropping) {
      return;
    }
    String msg = '';
    try {
      _cropping = true;

      //await showBusyingDialog();

      late EditImageInfo imageInfo;

      ///delay due to cropImageDataWithDartLibrary is time consuming on main thread
      ///it will block showBusyingDialog
      ///if you don't want to block ui, use compute/isolate,but it costs more time.
      //await Future.delayed(Duration(milliseconds: 200));

      ///if you don't want to block ui, use compute/isolate,but it costs more time.
      imageInfo = await cropImageDataWithDartLibrary(
          state: editorKey.currentState!, imageEncoding: _imageType);

      final String? filePath = await ImageSaver.save(
          '${_memoryImage!.name}.${_imageType.toLowerCase()}', imageInfo.data!);
      // var filePath = await ImagePickerSaver.saveFile(fileData: fileData);

      msg = 'save image : $filePath';
    } catch (e, stack) {
      msg = 'save failed: $e\n $stack';
      print(msg);
    }

    //Navigator.of(context).pop();
    showToast(msg);
    _cropping = false;
  }

  Future<void> _getImage() async {
    try {
      setImage(await pickImage(context));
    } catch (e) {
      showToast("error: $e");
    }
  }

  void setImage(CustomImage? image) {
    _memoryImage = image;
    //when back to current page, may be editorKey.currentState is not ready.
    Future<void>.delayed(const Duration(milliseconds: 200), () {
      setState(() {
        editorKey.currentState?.reset();
      });
    });
  }
}

class CustomEditorCropLayerPainter extends EditorCropLayerPainter {
  const CustomEditorCropLayerPainter();
  @override
  void paintCorners(
      Canvas canvas, Size size, ExtendedImageCropLayerPainter painter) {
    final Paint paint = Paint()
      ..color = painter.cornerColor
      ..style = PaintingStyle.fill;
    final Rect cropRect = painter.cropRect;
    const double radius = 6;
    canvas.drawCircle(Offset(cropRect.left, cropRect.top), radius, paint);
    canvas.drawCircle(Offset(cropRect.right, cropRect.top), radius, paint);
    canvas.drawCircle(Offset(cropRect.left, cropRect.bottom), radius, paint);
    canvas.drawCircle(Offset(cropRect.right, cropRect.bottom), radius, paint);
  }
}

class CircleEditorCropLayerPainter extends EditorCropLayerPainter {
  const CircleEditorCropLayerPainter();

  @override
  void paintCorners(
      Canvas canvas, Size size, ExtendedImageCropLayerPainter painter) {
    // do nothing
  }

  @override
  void paintMask(
      Canvas canvas, Size size, ExtendedImageCropLayerPainter painter) {
    final Rect rect = Offset.zero & size;
    final Rect cropRect = painter.cropRect;
    final Color maskColor = painter.maskColor;
    canvas.saveLayer(rect, Paint());
    canvas.drawRect(
        rect,
        Paint()
          ..style = PaintingStyle.fill
          ..color = maskColor);
    canvas.drawCircle(cropRect.center, cropRect.width / 2.0,
        Paint()..blendMode = BlendMode.clear);
    canvas.restore();
  }

  @override
  void paintLines(
      Canvas canvas, Size size, ExtendedImageCropLayerPainter painter) {
    final Rect cropRect = painter.cropRect;
    if (painter.pointerDown) {
      canvas.save();
      canvas.clipPath(Path()..addOval(cropRect));
      super.paintLines(canvas, size, painter);
      canvas.restore();
    }
  }
}
