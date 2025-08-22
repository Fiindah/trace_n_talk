import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:trace_n_talk/config.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final FlutterTts flutterTts = FlutterTts();
  final SpeechToText speechToText = SpeechToText();
  bool _isListening = false;
  String _lastWords = '';
  String _currentLocaleId = 'id-ID';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    _initStt();
  }

  @override
  void dispose() {
    flutterTts.stop();
    speechToText.stop();
    super.dispose();
  }

  void _initTts() async {
    await flutterTts.setLanguage('zh-CN');
    await flutterTts.setSpeechRate(0.5);
  }

  void _initStt() async {
    bool available = await speechToText.initialize();
    if (available) {
      setState(() {});
    } else {
      debugPrint('STT tidak tersedia');
    }
  }

  Future<void> _processInputWithGemini(String input) async {
    setState(() {
      _isLoading = true;
    });

    if (Config.apiKey == "YOUR_API_KEY_HERE" || Config.apiKey.isEmpty) {
      await _speakResponse(
        "Mohon maaf, API Key belum diatur. Silakan periksa file konfigurasi Anda.",
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    const apiUrl =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-05-20:generateContent?key=";

    final requestBody = {
      'contents': [
        {
          'parts': [
            {
              'text':
                  "Balas pertanyaan ini dalam bahasa Mandarin. Jawab singkat dan natural. Jika pertanyaan dalam bahasa Inggris atau Indonesia, terjemahkan juga. Pertanyaannya adalah: '$input'",
            },
          ],
        },
      ],
    };

    try {
      final response = await http.post(
        Uri.parse('$apiUrl${Config.apiKey}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode != 200 || responseData['candidates'] == null) {
        throw Exception(
          'API error: ${responseData['error']['message'] ?? "Unknown error"}',
        );
      }

      String responseText =
          responseData['candidates'][0]['content']['parts'][0]['text'];
      await _speakResponse(responseText);
    } catch (e) {
      debugPrint('Error memproses input: $e');
      await _speakResponse("对不起，出现了一些问题。");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _speakResponse(String text) async {
    await flutterTts.speak(text);
  }

  void _toggleListening() async {
    if (_isListening) {
      speechToText.stop();
      setState(() {
        _isListening = false;
      });
    } else {
      bool available = await speechToText.initialize(
        onStatus: (status) {
          if (status == 'listening') {
            setState(() {
              _isListening = true;
            });
          } else {
            setState(() {
              _isListening = false;
            });
          }
        },
      );
      if (available) {
        setState(() {
          _lastWords = '';
        });
        await speechToText.listen(
          onResult: (result) {
            setState(() {
              _lastWords = result.recognizedWords;
            });
            if (result.finalResult) {
              _processInputWithGemini(_lastWords);
            }
          },
          listenFor: const Duration(seconds: 5),
          localeId: _currentLocaleId,
        );
      }
    }
  }

  void _changeLocale(String newLocale) {
    setState(() {
      _currentLocaleId = newLocale;
      speechToText.stop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Percakapan dengan AI'),
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: _changeLocale,
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(value: 'id-ID', child: Text('Indonesia')),
                const PopupMenuItem(value: 'zh-CN', child: Text('Mandarin')),
              ];
            },
            icon: const Icon(Icons.language),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Tekan tombol mikrofon untuk berbicara',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'Bahasa: ${_currentLocaleId == 'id-ID' ? 'Indonesia' : 'Mandarin'}',
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: _toggleListening,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isLoading
                          ? [Colors.grey, Colors.grey]
                          : (_isListening
                                ? [Colors.redAccent, Colors.red]
                                : [Colors.blueAccent, Colors.lightBlue]),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 3,
                        blurRadius: 7,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isLoading
                        ? Icons.hourglass_top
                        : (_isListening ? Icons.mic_off : Icons.mic),
                    color: Colors.white,
                    size: 55,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _isLoading
                    ? 'Memproses...'
                    : (_isListening ? 'Mendengarkan...' : 'Menunggu...'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: _isLoading
                      ? Colors.grey
                      : (_isListening ? Colors.redAccent : Colors.black54),
                ),
              ),
              const SizedBox(height: 30),
              Card(
                elevation: 6,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Text(
                        'Kalimat yang terdeteksi:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _lastWords.isEmpty ? '-' : _lastWords,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
