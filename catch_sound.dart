import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:web_socket_channel/io.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AudioStreamScreen(),
    );
  }
}

class AudioStreamScreen extends StatefulWidget {
  @override
  _AudioStreamScreenState createState() => _AudioStreamScreenState();
}

class _AudioStreamScreenState extends State<AudioStreamScreen> {
  final TextEditingController _ipController = TextEditingController();
  late IOWebSocketChannel _channel;
  bool _isConnected = false;
  late FlutterSoundPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = FlutterSoundPlayer();
    _audioPlayer.openPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.closePlayer();
    _ipController.dispose();
    _channel.sink.close();
    super.dispose();
  }

  void _connectToServer() {
    String ipAddress = _ipController.text.trim();
    _channel = IOWebSocketChannel.connect('ws://$ipAddress:1010');
    _channel.stream.listen((message) {
      Uint8List audioData = Uint8List.fromList(message);
      _playAudioFromStream(audioData);

      _showSnackbar('Audio data received from server');
    }, onDone: () {
      setState(() {
        _isConnected = false;
      });
    }, onError: (error) {
      _showSnackbar('Error: $error');
      setState(() {
        _isConnected = false;
      });
    });

    setState(() {
      _isConnected = true;
    });
  }

  Future<void> _playAudioFromStream(Uint8List audioData) async {
    try {
      _showSnackbar('data: $audioData');

      await _audioPlayer.startPlayer(
        fromDataBuffer: audioData,
        codec: Codec.pcm16,
        sampleRate: 48000,
        numChannels: 2,
      );
    } catch (e) {
      _showSnackbar('Error playing audio: $e');
    }
  }

  //Future<void> _playAudioFromStream(Uint8List audioData) async {
  //try {
  //final audioSource = AudioSource.uri(Uri.dataFromString(
  //base64.encode(audioData), // Ses verisi base64 kodlanarak dönüştürülüyor
  //mimeType: 'audio/pcm', // Ses verisinin MIME türü
  //encoding: Encoding.getByName('utf-8')!, // Kodlama türü
  //));

  //await _audioPlayer.setAudioSource(audioSource);
  //await _audioPlayer.play();
  //_showSnackbar('Audio streaming started');
  //} catch (e) {
  //print('Error playing audio: $e');
  //_showAlertDialog('Playback Error', e.toString());
  //}
  //}

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Audio Stream Player'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _ipController,
              decoration: InputDecoration(
                labelText: 'Enter Server IP Address',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.numberWithOptions(
                signed: false,
                decimal: false,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isConnected ? null : _connectToServer,
              child: Text(_isConnected ? 'Connected' : 'Connect'),
            ),
            SizedBox(height: 16),
            if (_isConnected)
              Text(
                'Listening to audio stream...',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}
