import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';


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
                        isNewGame: true,
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
  final bool isNewGame;

  const GameScreen({
    super.key,
    this.isTimedMode = false,
    this.timeLimit,
    this.isNewGame = true,
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

  @override
  void initState() {
    super.initState();
    _remainingTime = widget.timeLimit ?? 60;

    if (widget.isNewGame) {
      _initializeGrid();
      _clearSavedGame();
    } else {
      _loadGame();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadGame() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSavedGame = prefs.getBool('hasSavedGame') ?? false;

    if (hasSavedGame) {
      final gameState = prefs.getString('gameState');
      if (gameState != null) {
        final parts = gameState.split('|');
        _currentRow = int.parse(parts[0]);
        _currentCol = int.parse(parts[1]);
        _remainingTime = int.parse(parts[2]);
        _isPaused = parts[3] == 'true';
        _gameOver = parts[4] == 'true';

        final gridState = parts[5];
        _grid = List.generate(6, (row) {
          return List.generate(5, (col) {
            final index = row * 5 + col;
            final letter = gridState[index * 2];
            final status = LetterStatus.values[int.parse(gridState[index * 2 + 1])];
            return Letter(letter, status);
          });
        });

        setState(() {});
      } else {
        _initializeGrid();
      }
    } else {
      _initializeGrid();
    }

    if (widget.isTimedMode && !_gameOver && !_isPaused) {
      _startTimer();
    }
  }

  Future<void> _saveGame() async {
    final prefs = await SharedPreferences.getInstance();

    // Serialize grid state
    final gridState = StringBuffer();
    for (int row = 0; row < 6; row++) {
      for (int col = 0; col < 5; col++) {
        gridState.write(_grid[row][col].value);
        gridState.write(_grid[row][col].status.index);
      }
    }

    final gameState = '$_currentRow|$_currentCol|$_remainingTime|$_isPaused|$_gameOver|${gridState.toString()}';
    await prefs.setString('gameState', gameState);
    await prefs.setBool('hasSavedGame', true);
  }

  Future<void> _clearSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('gameState');
    await prefs.setBool('hasSavedGame', false);
  }

  void _initializeGrid() {
    _grid = List.generate(6, (row) {
      return List.generate(5, (col) => Letter('', LetterStatus.empty));
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && !_gameOver) {
        setState(() {
          if (_remainingTime > 0) {
            _remainingTime--;
          } else {
            _timer?.cancel();
            _gameOver = true;
            _showTimeUpDialog();
          }
        });
        _saveGame();
      }
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

    _saveGame();
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

    _saveGame();
  }

  void _pauseGame() {
    setState(() {
      _isPaused = true;
      _timer?.cancel();
    });

    _saveGame();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text('Game Paused', style: TextStyle(color: Colors.white)),
        content: const Text('Your progress has been saved.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isPaused = false;
              });
              if (widget.isTimedMode && !_gameOver) {
                _startTimer();
              }
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
              _clearSavedGame();
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
              _clearSavedGame();
            },
            child: const Text('Share', style: TextStyle(color: Colors.blue)),
          ),
          TextButton(
            onPressed: () {
              _clearSavedGame();
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
              _clearSavedGame();
            },
            child: const Text('Share', style: TextStyle(color: Colors.blue)),
          ),
          TextButton(
            onPressed: () {
              _clearSavedGame();
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
      SnackBar(
        content: const Text("Score copied to clipboard!"),
        backgroundColor: const Color(0xFF2D2D2D),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );

    // Copy to clipboard
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
          onPressed: _pauseGame,
          icon: const Icon(Icons.pause_circle_outline_rounded, size: 20),
          label: const Text("Pause"),
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