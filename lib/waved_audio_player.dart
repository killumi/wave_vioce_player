// ignore_for_file: library_private_types_in_public_api

library waved_audio_player;

import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:waved_audio_player/wave_form_painter.dart';
import 'package:waved_audio_player/waved_audio_player_error.dart';

// ignore: must_be_immutable
class WavedAudioPlayer extends StatefulWidget {
  Source source;
  Color playedColor;
  Color unplayedColor;
  Color iconColor;
  Color iconBackgoundColor;
  double barWidth;
  double spacing;
  double waveHeight;
  double buttonSize;
  double waveWidth;
  bool showTiming;
  TextStyle? timingStyle;
  void Function(WavedAudioPlayerError)? onError;
  WavedAudioPlayer(
      {super.key,
      required this.source,
      this.playedColor = Colors.blue,
      this.unplayedColor = Colors.grey,
      this.iconColor = Colors.blue,
      this.iconBackgoundColor = Colors.white,
      this.barWidth = 2,
      this.spacing = 4,
      this.waveWidth = 200,
      this.buttonSize = 40,
      this.showTiming = true,
      this.timingStyle,
      this.onError,
      this.waveHeight = 35});

  @override
  _WavedAudioPlayerState createState() => _WavedAudioPlayerState();
}

AudioPlayer? activePlayer;

class _WavedAudioPlayerState extends State<WavedAudioPlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<double> waveformData = [];
  Duration audioDuration = Duration.zero;
  Duration currentPosition = Duration.zero;
  bool isPlaying = false;
  bool isPausing = true;
  Uint8List? _audioBytes;
  Duration? lastRemainingTime;

  @override
  void initState() {
    super.initState();
    _loadWaveform();
    _setupAudioPlayer();
  }

  Widget _buildTimingText() {
    if (audioDuration == Duration.zero) {
      // Если аудио ещё загружается, показываем временную надпись
      return Text(
        _formatDuration(audioDuration), // Показывает 00:00 при загрузке
        style: widget.timingStyle,
      );
    }

    // Если на паузе, показываем сохранённое время
    if (!isPlaying && lastRemainingTime != null) {
      return Text(
        _formatDuration(lastRemainingTime!),
        style: widget.timingStyle,
      );
    }

    // Показываем оставшееся время
    final remaining = audioDuration - currentPosition;
    return Text(
      _formatDuration(remaining), // Используем общий формат MM:SS
      style: widget.timingStyle,
    );
  }

  Future<void> _loadWaveform() async {
    try {
      if (_audioBytes == null) {
        if (widget.source is AssetSource) {
          _audioBytes = await _loadAssetAudioWaveform(
              (widget.source as AssetSource).path);
        } else if (widget.source is UrlSource) {
          _audioBytes =
              await _loadRemoteAudioWaveform((widget.source as UrlSource).url);
        } else if (widget.source is DeviceFileSource) {
          _audioBytes = await _loadDeviceFileAudioWaveform(
              (widget.source as DeviceFileSource).path);
        } else if (widget.source is BytesSource) {
          _audioBytes = (widget.source as BytesSource).bytes;
        }

        waveformData = _extractWaveformData(_audioBytes!);

        if (mounted) {
          setState(() {});
        }
      }

      await _audioPlayer.setSource(
          BytesSource(_audioBytes!, mimeType: widget.source.mimeType));

      // Получаем длительность
      final duration = await _audioPlayer.getDuration();
      if (duration != null) {
        if (mounted) {
          setState(() {
            audioDuration = duration;
          });
        }
      }
    } catch (e) {
      _callOnError(WavedAudioPlayerError("Error loading audio: $e"));
    }
  }

  Future<Uint8List?> _loadDeviceFileAudioWaveform(String filePath) async {
    try {
      final File file = File(filePath);
      final Uint8List audioBytes = await file.readAsBytes();
      return audioBytes;
    } catch (e) {
      _callOnError(WavedAudioPlayerError("Error loading file audio: $e"));
    }
    return null;
  }

  Future<Uint8List?> _loadAssetAudioWaveform(String path) async {
    try {
      final ByteData bytes = await rootBundle.load(path);
      return bytes.buffer.asUint8List();
    } catch (e) {
      _callOnError(WavedAudioPlayerError("Error loading asset audio: $e"));
    }
    return null;
  }

  Future<Uint8List?> _loadRemoteAudioWaveform(String url) async {
    try {
      final HttpClient httpClient = HttpClient();
      final HttpClientRequest request = await httpClient.getUrl(Uri.parse(url));
      final HttpClientResponse response = await request.close();

      if (response.statusCode == 200) {
        return await consolidateHttpClientResponseBytes(response);
      } else {
        _callOnError(WavedAudioPlayerError(
            "Failed to load audio: ${response.statusCode}"));
      }

      httpClient.close();
    } catch (e) {
      _callOnError(WavedAudioPlayerError("Error loading audio: $e"));
    }
    return null;
  }

  _callOnError(WavedAudioPlayerError error) {
    if (widget.onError == null) return;
    print('\x1B[31m ${error.message}\x1B[0m');
    widget.onError!(error);
  }

  void _setupAudioPlayer() async {
    await Future.delayed(const Duration(seconds: 1));
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (mounted) {
        setState(() {
          isPlaying = (state == PlayerState.playing);
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          isPlaying = false; // Останавливаем
          currentPosition = Duration.zero; // Возвращаем на начало
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((Duration duration) {
      if (mounted) {
        setState(() {
          audioDuration = duration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((Duration position) {
      if (mounted) {
        setState(() {
          currentPosition = position;
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (hours > 0) {
      return "${twoDigits(hours)}:$minutes:$seconds"; // Format as HH:MM:SS
    } else {
      return "$minutes:$seconds"; // Format as MM:SS
    }
  }

  List<double> _extractWaveformData(Uint8List audioBytes) {
    List<double> waveData = [];
    int step = (audioBytes.length /
            (widget.waveWidth / (widget.barWidth + widget.spacing)))
        .floor();
    for (int i = 0; i < audioBytes.length; i += step) {
      waveData.add(audioBytes[i] / 255);
    }
    waveData.add(audioBytes[audioBytes.length - 1] / 255);
    return waveData;
  }

  void _onWaveformTap(double tapX, double width) {
    double tapPercent = tapX / width;
    Duration newPosition = audioDuration * tapPercent;
    _audioPlayer.seek(newPosition);
  }

  void _playAudio() async {
    if (_audioBytes == null) return;
    if (activePlayer != null && activePlayer != _audioPlayer) {
      // Останавливаем текущий активный плеер
      await activePlayer!.stop();
    }

    // Переключаем глобальную переменную на текущий плеер
    activePlayer = _audioPlayer;

    // Если достигли конца, возвращаемся в начало
    if (currentPosition >= audioDuration) {
      await _audioPlayer.seek(Duration.zero);
    }

    // Обнуляем lastRemainingTime, так как начинается активное воспроизведение
    lastRemainingTime = null;

    // Проигрываем в зависимости от текущего состояния
    isPausing
        ? await _audioPlayer.resume()
        : await _audioPlayer
            .play(BytesSource(_audioBytes!, mimeType: widget.source.mimeType));
  }

  void _pauseAudio() async {
    lastRemainingTime = audioDuration - currentPosition;
    _audioPlayer.pause();
    isPausing = true;
  }

  @override
  Widget build(BuildContext context) {
    return (waveformData.isNotEmpty)
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  isPlaying ? _pauseAudio() : _playAudio();
                  setState(() {
                    isPlaying = !isPlaying;
                  });
                },
                child: Container(
                  height: widget.buttonSize,
                  width: widget.buttonSize,
                  decoration: BoxDecoration(
                    color: widget.iconBackgoundColor,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: widget.iconColor,
                    size: 4 * widget.buttonSize / 5,
                  ),
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              GestureDetector(
                onTapDown: (TapDownDetails details) {
                  // Call _onWaveformTap when the user taps on the waveform
                  _onWaveformTap(details.localPosition.dx, widget.waveWidth);
                },
                child: CustomPaint(
                  size: Size(widget.waveWidth, widget.waveHeight),
                  painter: WaveformPainter(
                      waveformData,
                      currentPosition.inMilliseconds /
                          (audioDuration.inMilliseconds == 0
                              ? 1
                              : audioDuration.inMilliseconds),
                      playedColor: widget.playedColor,
                      unplayedColor: widget.unplayedColor,
                      barWidth: widget.barWidth), // Use your wave data
                ),
              ),
              if (widget.showTiming)
                const SizedBox(
                  width: 10,
                ),
              if (widget.showTiming) Center(child: _buildTimingText())
            ],
          )
        : SizedBox(
            width: widget.waveWidth + widget.buttonSize,
            height: max(widget.waveHeight, widget.buttonSize),
            child: Center(
              child: LinearProgressIndicator(
                color: widget.playedColor,
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          );
  }
}
