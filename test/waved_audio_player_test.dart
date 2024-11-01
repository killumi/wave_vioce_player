import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waved_audio_player/waved_audio_player.dart';
import 'package:flutter/material.dart';



void main() {

  testWidgets('renders the WavedAudioPlayer widget correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WavedAudioPlayer(
            source: AssetSource('assets/sample.mp3'),
            iconColor: Colors.red,
            iconBackgoundColor: Colors.blue,
            waveWidth: 100,
            barWidth: 2,
            buttonSize: 40,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    expect(find.byIcon(Icons.pause_rounded), findsNothing);
  });

  testWidgets('Play button toggles to pause when audio starts playing',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WavedAudioPlayer(
            source: AssetSource('assets/sample.mp3'),
            iconColor: Colors.red,
            iconBackgoundColor: Colors.blue,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

    await tester.tap(find.byType(Container).first);

    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget );
  });

  testWidgets('Error callback is called on invalid file path',
      (WidgetTester tester) async {
    bool onErrorCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WavedAudioPlayer(
            source: AssetSource('invalid_path.mp3'),
            onError: (error) {
              onErrorCalled = true;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(onErrorCalled, isTrue);
  });
}
