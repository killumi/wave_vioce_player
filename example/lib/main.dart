import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:waved_audio_player/waved_audio_player.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Package Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String filePath = "";

  Future<void> pickFile() async {
    String? _filePath = await FilePicker.platform
        .pickFiles(type: FileType.audio)
        .then((result) => result?.files.first.path);

    if (_filePath != null) {
      // Use the filePath to load audio
      setState(() {
        filePath = _filePath;
      });
      print("Selected file path: $filePath");
    } else {
      print("No file selected");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text("Waved audio player example")),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
                onPressed: () {
                  pickFile();
                },
                child: const Text("Pick File")),
            const SizedBox(
              height: 30,
            ),
            const Text(
              "Play from Asset:",
              style: TextStyle(
                fontSize: 20,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            WavedAudioPlayer(
              source: AssetSource('assets/sample.mp3', mimeType: "audio/mp3"),
              onError: (err) {
                print('$err');
              },
            ),
            const SizedBox(
              height: 30,
            ),
            const Text(
              "Play from Url:",
              style: TextStyle(
                fontSize: 20,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            WavedAudioPlayer(
              source: UrlSource(
                  'https://download.samplelib.com/mp3/sample-3s.mp3',
                  mimeType: "audio/mp3"),
              playedColor: Colors.white,
              iconColor: Colors.red,
            ),
            const SizedBox(
              height: 30,
            ),
            if (filePath.isNotEmpty)
              const Text(
                "Play from Device:",
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
            const SizedBox(
              height: 10,
            ),
            if (filePath.isNotEmpty)
              WavedAudioPlayer(
                  source: DeviceFileSource(filePath, mimeType: 'audio/mp3')),
          ],
        ),
      ),
    );
  }
}
