import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wordle Pro',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Text(
                'WORDLE',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF3E8642),
                  letterSpacing: 4.0,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Guess the hidden word',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              _buildGameButton(
                text: 'New Game',
                icon: Icons.play_arrow_rounded,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => GameScreen(isTimedMode: false)),
                ),
              ),
              const SizedBox(height: 16),
              _buildGameButton(
                text: 'Timed Mode',
                icon: Icons.timer_rounded,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TimedModeScreen()),
                ),
              ),
              const Spacer(flex: 2),
              const Text(
                'Made with ❤️ by Swaja Robotics',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TimedModeScreen extends StatefulWidget {
  const TimedModeScreen({super.key});

  @override
  State<TimedModeScreen> createState() => _TimedModeScreenState();
}

class _TimedModeScreenState extends State<TimedModeScreen> {
  int selectedSeconds = 60;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Timed Mode',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Select time limit",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Slider(
              min: 30,
              max: 300,
              divisions: 9,
              value: selectedSeconds.toDouble(),
              label: "$selectedSeconds seconds",
              onChanged: (val) {
                setState(() {
                  selectedSeconds = val.round();
                });
              },
            ),
            const SizedBox(height: 10),
            Text(
              "$selectedSeconds seconds",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GameScreen(
                        isTimedMode: true,
                        timeLimit: selectedSeconds,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1E1E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'Start Game',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  final bool isTimedMode;
  final int? timeLimit;

  const GameScreen({
    super.key,
    this.isTimedMode = false,
    this.timeLimit,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int _remainingTime = 60;
  late List<List<Letter>> _grid;
  int _currentRow = 0;
  int _currentCol = 0;
  String _targetWord = "FLUTTER";
  Timer? _timer;
  bool _isPaused = false;
  bool _gameOver = false;
  bool _gameWon = false;

  @override
  void initState() {
    super.initState();
    _remainingTime = widget.timeLimit ?? 60;
    _initializeGrid();

    // Start timer immediately for timed mode
    if (widget.isTimedMode) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initializeGrid() {
    _grid = List.generate(6, (row) {
      return List.generate(5, (col) => Letter('', LetterStatus.empty));
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && !_gameOver && mounted) {
        setState(() {
          if (_remainingTime > 0) {
            _remainingTime--;
          } else {
            _timer?.cancel();
            _gameOver = true;
            _showTimeUpDialog();
          }
        });
      }
    });
  }

  void _pauseGame() {
    if (_gameOver) return;

    setState(() {
      _isPaused = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text('Game Paused', style: TextStyle(color: Colors.white)),
        content: const Text('Take your time!', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isPaused = false;
              });
            },
            child: const Text('Resume', style: TextStyle(color: Colors.blue)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Quit', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  void _resumeGame() {
    setState(() {
      _isPaused = false;
    });
  }

  void _onKeyPressed(String key) {
    if (_gameOver || _isPaused) return;

    if (key == 'ENTER') {
      _checkWord();
    } else if (key == 'BACKSPACE') {
      _deleteLetter();
    } else if (_currentCol < 5) {
      _addLetter(key);
    }
  }

  void _addLetter(String letter) {
    setState(() {
      _grid[_currentRow][_currentCol] = Letter(letter, LetterStatus.untried);
      _currentCol++;
    });
  }

  void _deleteLetter() {
    if (_currentCol > 0) {
      setState(() {
        _currentCol--;
        _grid[_currentRow][_currentCol] = Letter('', LetterStatus.empty);
      });
    }
  }

  void _checkWord() {
    if (_currentCol < 5) return; // Word not complete

    String guessedWord = '';
    for (int i = 0; i < 5; i++) {
      guessedWord += _grid[_currentRow][i].value;
    }

    // Check each letter
    for (int i = 0; i < 5; i++) {
      String letter = _grid[_currentRow][i].value;
      if (_targetWord[i] == letter) {
        _grid[_currentRow][i] = Letter(letter, LetterStatus.correct);
      } else if (_targetWord.contains(letter)) {
        _grid[_currentRow][i] = Letter(letter, LetterStatus.present);
      } else {
        _grid[_currentRow][i] = Letter(letter, LetterStatus.absent);
      }
    }

    setState(() {
      if (guessedWord == _targetWord) {
        _gameOver = true;
        _gameWon = true;
        _timer?.cancel();
        _showWinDialog();
      } else if (_currentRow == 5) {
        _gameOver = true;
        _timer?.cancel();
        _showLoseDialog();
      } else {
        _currentRow++;
        _currentCol = 0;
      }
    });
  }

  void _showTimeUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text('Time\'s Up!', style: TextStyle(color: Colors.white)),
        content: Text('The word was: $_targetWord', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text('You Win!', style: TextStyle(color: Colors.white)),
        content: Text('You guessed the word in ${_currentRow + 1} ${_currentRow + 1 == 1 ? 'try' : 'tries'}!',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              _shareScore();
              Navigator.pop(context);
            },
            child: const Text('Share', style: TextStyle(color: Colors.blue)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  void _showLoseDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text('Game Over', style: TextStyle(color: Colors.white)),
        content: Text('The word was: $_targetWord', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              _shareScore();
              Navigator.pop(context);
            },
            child: const Text('Share', style: TextStyle(color: Colors.blue)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  void _shareScore() {
    String result = '';
    for (int row = 0; row <= _currentRow; row++) {
      for (int col = 0; col < 5; col++) {
        switch (_grid[row][col].status) {
          case LetterStatus.correct:
            result += '🟩';
            break;
          case LetterStatus.present:
            result += '🟨';
            break;
          case LetterStatus.absent:
            result += '⬛';
            break;
          default:
            result += '⬜';
        }
      }
      result += '\n';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Score copied to clipboard!"),
        backgroundColor: Color(0xFF2D2D2D),
      ),
    );

    Clipboard.setData(ClipboardData(text: 'Wordle Pro Score:\n$result'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'WORDLE',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
        actions: [
          if (widget.isTimedMode)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(_remainingTime ~/ 60).toString().padLeft(2, '0')}:${(_remainingTime % 60).toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: _remainingTime <= 10 ? Colors.red : Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 32),
            _buildGameGrid(),
            const Spacer(),
            _buildKeyboard(),
            const SizedBox(height: 24),
            _buildActionButtons(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildGameGrid() {
    return Center(
      child: Column(
        children: List.generate(6, (rowIndex) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (colIndex) {
                final letter = _grid[rowIndex][colIndex];
                Color bgColor;
                Color borderColor = const Color(0xFF3A3A3A);

                switch (letter.status) {
                  case LetterStatus.empty:
                    bgColor = Colors.transparent;
                    break;
                  case LetterStatus.untried:
                    bgColor = Colors.transparent;
                    break;
                  case LetterStatus.correct:
                    bgColor = const Color(0xFF538D4E);
                    borderColor = const Color(0xFF538D4E);
                    break;
                  case LetterStatus.present:
                    bgColor = const Color(0xFFB59F3B);
                    borderColor = const Color(0xFFB59F3B);
                    break;
                  case LetterStatus.absent:
                    bgColor = const Color(0xFF3A3A3A);
                    borderColor = const Color(0xFF3A3A3A);
                    break;
                }

                return Container(
                  width: 50,
                  height: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border.all(color: borderColor, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      letter.value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildKeyboard() {
    return Column(
      children: [
        _buildKeyboardRow("QWERTYUIOP"),
        const SizedBox(height: 8),
        _buildKeyboardRow("ASDFGHJKL"),
        const SizedBox(height: 8),
        _buildKeyboardRow("ZXCVBNM", isLastRow: true),
      ],
    );
  }

  Widget _buildKeyboardRow(String keys, {bool isLastRow = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLastRow)
          GestureDetector(
            onTap: () => _onKeyPressed('BACKSPACE'),
            child: Container(
              width: 50,
              height: 50,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.backspace, color: Colors.white, size: 20),
            ),
          ),
        ...keys.split('').map((key) {
          return GestureDetector(
            onTap: () => _onKeyPressed(key),
            child: Container(
              width: 30,
              height: 50,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  key,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
        if (isLastRow)
          GestureDetector(
            onTap: () => _onKeyPressed('ENTER'),
            child: Container(
              width: 50,
              height: 50,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Text(
                  "ENTER",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: _isPaused ? _resumeGame : _pauseGame,
          icon: Icon(
            _isPaused ? Icons.play_arrow_rounded : Icons.pause_circle_outline_rounded,
            size: 20,
          ),
          label: Text(_isPaused ? "Resume" : "Pause"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2D2D2D),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _shareScore,
          icon: const Icon(Icons.share_rounded, size: 20),
          label: const Text("Share"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2D2D2D),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    );
  }
}

class Letter {
  final String value;
  final LetterStatus status;

  Letter(this.value, this.status);
}

enum LetterStatus {
  empty,
  untried,
  correct,
  present,
  absent,
}