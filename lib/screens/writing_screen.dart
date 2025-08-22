import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:trace_n_talk/screens/db_helper.dart';

class CharacterWritingResult {
  final int? id;
  final String character;
  final bool isCorrect;
  final DateTime date;

  CharacterWritingResult({
    this.id,
    required this.character,
    required this.isCorrect,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'character': character,
      'isCorrect': isCorrect ? 1 : 0,
      'date': date.toIso8601String(),
    };
  }
}

class WritingScreen extends StatefulWidget {
  const WritingScreen({super.key});

  @override
  State<WritingScreen> createState() => _WritingScreenState();
}

class _WritingScreenState extends State<WritingScreen> {
  final String targetCharacter = '我';
  final int correctStrokeCount = 7;
  List<List<Offset>> drawingPaths = [];
  List<Offset> currentPath = [];
  late DatabaseHelper dbHelper;
  String message = 'Silakan tulis karakter \'我\'';

  @override
  void initState() {
    super.initState();
    dbHelper = DatabaseHelper();
  }

  Future<void> _saveResult(bool result) async {
    final CharacterWritingResult writingResult = CharacterWritingResult(
      id: null,
      character: targetCharacter,
      isCorrect: result,
      date: DateTime.now(),
    );
    await dbHelper.insertResult(writingResult.toMap());
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      currentPath = [details.localPosition];
      drawingPaths.add(currentPath);
      message = 'Goresan: ${drawingPaths.length} dari $correctStrokeCount';
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      currentPath.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {}

  void _onSubmit() {
    bool isCorrectStrokeCount = drawingPaths.length == correctStrokeCount;
    if (isCorrectStrokeCount) {
      _showResultDialog(true);
      _saveResult(true);
    } else {
      _showResultDialog(false);
      _saveResult(false);
    }
  }

  void _showResultDialog(bool result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(result ? '✅ Benar!' : '❌ Salah!'),
          content: Text(
            result ? 'Kerja bagus!' : 'Jumlah goresan tidak tepat. Coba lagi.',
            style: const TextStyle(fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK', style: TextStyle(fontSize: 16)),
              onPressed: () {
                Navigator.of(context).pop();
                _resetCanvas();
              },
            ),
          ],
        );
      },
    );
  }

  void _resetCanvas() {
    setState(() {
      drawingPaths = [];
      currentPath = [];
      message = 'Silakan tulis karakter \'我\'';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              const Text(
                'Latihan Menulis Karakter',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: const TextStyle(fontSize: 18, color: Colors.black87),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 8,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Colors.white, Color(0xFFE3F2FD)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          targetCharacter,
                          style: const TextStyle(
                            fontSize: 200,
                            color: Color.fromARGB(100, 150, 150, 150),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: GestureDetector(
                          onPanStart: _onPanStart,
                          onPanUpdate: _onPanUpdate,
                          onPanEnd: _onPanEnd,
                          child: CustomPaint(
                            size: const Size(350, 350),
                            painter: CharacterPainter(drawingPaths),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _resetCanvas,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25,
                        vertical: 15,
                      ),
                      textStyle: const TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      elevation: 5,
                    ),
                    label: const Text('Reset'),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    onPressed: _onSubmit,
                    icon: const Icon(Icons.check_circle, color: Colors.white),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25,
                        vertical: 15,
                      ),
                      textStyle: const TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      elevation: 5,
                    ),
                    label: const Text('Periksa'),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class CharacterPainter extends CustomPainter {
  final List<List<Offset>> paths;

  CharacterPainter(this.paths);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10.0;

    for (var path in paths) {
      if (path.length > 1) {
        for (int i = 0; i < path.length - 1; i++) {
          canvas.drawLine(path[i], path[i + 1], paint);
        }
      } else if (path.isNotEmpty) {
        canvas.drawPoints(PointMode.points, path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
