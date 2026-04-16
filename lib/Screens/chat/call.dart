import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class AudioCallScreen extends StatefulWidget {
  final String username;
  final String profileImagePath;

  const AudioCallScreen({
    required this.username,
    required this.profileImagePath,
  });

  @override
  _AudioCallScreenState createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _startCall();
  }

  @override
  void dispose() {
    _endCall(); // Clean up when screen is closed
    super.dispose();
  }

  Future<void> _startCall() async {
    try {
      // 1. Get user media (audio only)
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });

      // 2. Create peer connection (you must handle signaling externally)
      _peerConnection = await createPeerConnection({});

      // 3. Add local stream
      _peerConnection?.addStream(_localStream!);

      // TODO: Implement offer/answer exchange through signaling server
    } catch (e) {
      print('Error starting call: $e');
    }
  }

  Future<void> _endCall() async {
    try {
      await _peerConnection?.close();
      await _localStream?.dispose();
      _peerConnection = null;
      _localStream = null;
    } catch (e) {
      print('Error ending call: $e');
    } finally {
      if (mounted) Navigator.pop(context);
    }
  }

  void _toggleMute() {
    if (_localStream != null) {
      final audioTrack = _localStream!
          .getAudioTracks()
          .firstWhere((track) => track.kind == 'audio');
      audioTrack.enabled = !audioTrack.enabled;

      setState(() {
        _isMuted = !audioTrack.enabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calling ${widget.username}'),
        backgroundColor: Color(0xFFF25F12),
        foregroundColor: Colors.black,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: AssetImage(widget.profileImagePath),
              onBackgroundImageError: (exception, stackTrace) {
                print("Error loading image");
              },
            ),
            SizedBox(height: 20),
            Text(
              'Connecting...',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(_isMuted ? Icons.mic_off : Icons.mic),
                  onPressed: _toggleMute,
                  iconSize: 40,
                  color: _isMuted ? Colors.grey : Color(0xFFF25F12),
                ),
                IconButton(
                  icon: Icon(Icons.call_end),
                  onPressed: _endCall,
                  iconSize: 40,
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
