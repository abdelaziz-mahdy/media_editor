// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:media_editor/image_editor.dart';
import 'package:media_editor/main.dart';
import 'package:http/http.dart' as http;
import 'package:media_editor/video_editor.dart';

Future<void> main() async {
  await loadAppFonts();
  TestWidgetsFlutterBinding.ensureInitialized();

  XFile? imageFile;
  // XFile? videoFile;
  setUp(() async {
    final byteData = await rootBundle.load('test_files/ForBiggerMeltdowns.jpg');
    final buffer = byteData.buffer;
    imageFile = XFile.fromData(
      buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
      name: 'test.png',
    );

    // final byteData2 =
    //     await rootBundle.load('test_files/ForBiggerMeltdowns.mp4');
    // final buffer2 = byteData2.buffer;
    // videoFile = XFile.fromData(
    //   buffer2.asUint8List(byteData2.offsetInBytes, byteData2.lengthInBytes),
    //   name: 'test.mp4',
    // );
  });
  testGoldens('Screenshots', (tester) async {
    await tester.pumpWidgetBuilder(const MyApp());

    await multiScreenGolden(tester, "Screenshots".toLowerCase(),
        customPump: (p0) => tester.pumpAndSettle(),
        devices: [
          Device.phone,
          Device.tabletLandscape.copyWith(name: 'desktop'),
        ]);
  });

  testGoldens('image editor', (tester) async {
    await tester.pumpWidgetBuilder(ImageEditor(file: imageFile!));
    await multiScreenGolden(tester, 'screenshots_image'.toLowerCase(),
        customPump: (p0) => tester.pump(Duration(minutes: 20)),
        devices: [
          Device.tabletLandscape.copyWith(name: 'desktop'),
          Device.phone,
        ]);
  });

  // testGoldens('video editor', (tester) async {
  //   await tester.pumpWidgetBuilder(VideoEditor(file: videoFile!));
  //   await multiScreenGolden(tester, 'screenshots_video'.toLowerCase(),
  //       customPump: (p0) => tester.pump(Duration(seconds: 5)),
  //       devices: [
  //         Device.phone,
  //         Device.tabletLandscape.copyWith(name: 'desktop'),
  //       ]);
  // });
}
