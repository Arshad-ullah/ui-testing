// number_logic_game.dart
//
// A self-contained "Number Logic" mini-game for a kids' IQ-training app.
// Drop this file into your Flutter project (lib/games/number_logic_game.dart)
// and navigate to `const NumberLogicGame()` from anywhere.
//
// Features:
//  - Two question types: number sequences (2 4 6 8 ?) and simple arithmetic (5 + 3 = ?)
//  - Adaptive difficulty: gets harder as the child answers correctly, easier after mistakes
//  - Multiple-choice answers (easier for young kids than typing) with big tappable cards
//  - Stars / streak system + animated feedback (no harsh "WRONG" buzzers)
//  - Lives system so a session always has a clear, friendly end
//  - Clean, colorful, rounded UI with subtle animations
//
// No external packages required — pure Flutter SDK.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum QuestionType { sequence, arithmetic }

class NumberQuestion {
  final QuestionType type;
  final String prompt; // e.g. "2  4  6  8  ?"  or  "5 + 3 = ?"
  final int answer;
  final List<int> options;

  NumberQuestion({
    required this.type,
    required this.prompt,
    required this.answer,
    required this.options,
  });
}

/// ---------------------------------------------------------------------
/// QUESTION GENERATOR (adaptive difficulty)
/// ---------------------------------------------------------------------
///
/// difficulty roughly ranges 1 (easiest) .. 10 (hardest).
/// Sequences: step size & starting number grow with difficulty,
/// occasionally introduces subtraction or multiplication-style steps.
/// Arithmetic: operand size and operator complexity grow with difficulty.

class QuestionGenerator {
  final Random _rng = Random();

  NumberQuestion generate(int difficulty) {
    final useSequence = _rng.nextBool();
    return useSequence
        ? _generateSequence(difficulty)
        : _generateArithmetic(difficulty);
  }

  NumberQuestion _generateSequence(int difficulty) {
    // Step size grows with difficulty; occasionally negative (counting down).
    final maxStep = 1 + (difficulty / 2).ceil(); // 1..6ish
    int step = 1 + _rng.nextInt(maxStep);
    final descending = difficulty > 3 && _rng.nextBool();
    if (descending) step = -step;

    final start = 1 + _rng.nextInt(5 + difficulty * 2);
    final length = 4; // show 4 numbers, ask for the 5th
    final seq = List<int>.generate(length, (i) => start + step * i);
    final answer = start + step * length;

    final prompt = '${seq.join('   ')}   ?';
    final options = _buildOptions(answer, spread: step.abs().clamp(1, 12));

    return NumberQuestion(
      type: QuestionType.sequence,
      prompt: prompt,
      answer: answer,
      options: options,
    );
  }

  NumberQuestion _generateArithmetic(int difficulty) {
    // Pick operator based on difficulty.
    final ops = difficulty < 3
        ? ['+', '-']
        : difficulty < 6
        ? ['+', '-', '×']
        : ['+', '-', '×'];
    final op = ops[_rng.nextInt(ops.length)];

    int a, b, answer;
    final maxVal = 5 + difficulty * 3; // grows with difficulty

    switch (op) {
      case '+':
        a = 1 + _rng.nextInt(maxVal);
        b = 1 + _rng.nextInt(maxVal);
        answer = a + b;
        break;
      case '-':
        a = 1 + _rng.nextInt(maxVal) + 5;
        b = 1 + _rng.nextInt(a); // ensure non-negative result
        answer = a - b;
        break;
      case '×':
        a = 1 + _rng.nextInt(min(4 + difficulty, 12));
        b = 1 + _rng.nextInt(min(4 + difficulty, 12));
        answer = a * b;
        break;
      default:
        a = 1;
        b = 1;
        answer = 2;
    }

    final prompt = '$a  $op  $b  =  ?';
    final options = _buildOptions(answer, spread: max(2, answer ~/ 4));

    return NumberQuestion(
      type: QuestionType.arithmetic,
      prompt: prompt,
      answer: answer,
      options: options,
    );
  }

  List<int> _buildOptions(int answer, {int spread = 3}) {
    final set = <int>{answer};
    while (set.length < 4) {
      final delta = (1 + _rng.nextInt(spread)) * (_rng.nextBool() ? 1 : -1);
      final candidate = answer + delta;
      if (candidate >= 0) set.add(candidate);
    }
    final list = set.toList()..shuffle(_rng);
    return list;
  }
}

/// ---------------------------------------------------------------------
/// MAIN GAME SCREEN
/// ---------------------------------------------------------------------

class NumberLogicGame extends StatefulWidget {
  const NumberLogicGame({super.key});

  @override
  State<NumberLogicGame> createState() => _NumberLogicGameState();
}

class _NumberLogicGameState extends State<NumberLogicGame>
    with TickerProviderStateMixin {
  final QuestionGenerator _generator = QuestionGenerator();

  late NumberQuestion _question;
  int _difficulty = 2;
  int _streak = 0;
  int _stars = 0;
  int _lives = 3;
  int? _selectedOption;
  bool _showFeedback = false;
  bool _wasCorrect = false;
  bool _gameOver = false;

  late AnimationController _promptController;
  late Animation<double> _promptScale;

  @override
  void initState() {
    super.initState();
    _promptController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _promptScale = CurvedAnimation(
      parent: _promptController,
      curve: Curves.elasticOut,
    );
    _nextQuestion();
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _nextQuestion() {
    setState(() {
      _question = _generator.generate(_difficulty);
      _selectedOption = null;
      _showFeedback = false;
    });
    _promptController.forward(from: 0);
  }

  void _restart() {
    setState(() {
      _difficulty = 2;
      _streak = 0;
      _stars = 0;
      _lives = 3;
      _gameOver = false;
    });
    _nextQuestion();
  }

  Future<void> _onAnswer(int option) async {
    if (_showFeedback || _gameOver) return;

    final correct = option == _question.answer;
    HapticFeedback.lightImpact();

    setState(() {
      _selectedOption = option;
      _showFeedback = true;
      _wasCorrect = correct;
    });

    if (correct) {
      _streak++;
      _stars++;
      // Increase difficulty every 2 correct in a row, cap at 10.
      if (_streak % 2 == 0) {
        _difficulty = min(10, _difficulty + 1);
      }
    } else {
      _streak = 0;
      _lives--;
      // Ease difficulty back down a bit so it doesn't feel punishing.
      _difficulty = max(1, _difficulty - 1);
    }

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    if (_lives <= 0) {
      setState(() => _gameOver = true);
    } else {
      _nextQuestion();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _gameOver ? _buildGameOver() : _buildGame()),
    );
  }

  // ---------------- UI: top bar (lives, stars, streak, difficulty) ------

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          // Lives as hearts
          Row(
            children: List.generate(3, (i) {
              final filled = i < _lives;
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  filled ? Icons.favorite : Icons.favorite_border,
                  color: const Color(0xFFFF6B81),
                  size: 22,
                ),
              );
            }),
          ),
          const Spacer(),
          // Difficulty indicator (kid-friendly: stars-of-difficulty bar)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: Color(0xFFFFC107), size: 16),
                const SizedBox(width: 4),
                Text(
                  'Lv $_difficulty',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Stars collected
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                color: Color(0xFFFFC107),
                size: 24,
              ),
              const SizedBox(width: 4),
              Text(
                '$_stars',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- UI: streak banner ----------------

  Widget _buildStreakBanner() {
    if (_streak < 2) return const SizedBox(height: 26);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Container(
          key: ValueKey(_streak),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF9A56), Color(0xFFFF6B81)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '🔥 $_streak in a row!',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- UI: question card ----------------

  Widget _buildQuestionCard() {
    final isSequence = _question.type == QuestionType.sequence;
    return ScaleTransition(
      scale: Tween<double>(begin: 0.85, end: 1.0).animate(_promptScale),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSequence
                ? [const Color(0xFF6C63FF), const Color(0xFF8E7CFF)]
                : [const Color(0xFF3FC1C9), const Color(0xFF59D5D9)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color:
                  (isSequence
                          ? const Color(0xFF6C63FF)
                          : const Color(0xFF3FC1C9))
                      .withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              isSequence ? 'What comes next?' : 'Solve it!',
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _question.prompt,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- UI: answer options grid ----------------

  Widget _buildOptions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
        children: _question.options.map((opt) {
          final isSelected = _selectedOption == opt;
          final isCorrectOpt = opt == _question.answer;

          Color bg = Colors.white;
          Color textColor = const Color(0xFF333333);
          Color borderColor = const Color(0xFFE3E0FF);

          if (_showFeedback) {
            if (isCorrectOpt) {
              bg = const Color(0xFF4CD964);
              textColor = Colors.white;
              borderColor = const Color(0xFF4CD964);
            } else if (isSelected && !isCorrectOpt) {
              bg = const Color(0xFFFF6B6B);
              textColor = Colors.white;
              borderColor = const Color(0xFFFF6B6B);
            }
          }

          return GestureDetector(
            onTap: () => _onAnswer(opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '$opt',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------------- UI: feedback toast ----------------

  Widget _buildFeedback() {
    if (!_showFeedback) return const SizedBox(height: 28);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _wasCorrect ? Icons.check_circle : Icons.refresh_rounded,
            color: _wasCorrect
                ? const Color(0xFF4CD964)
                : const Color(0xFFFF9F43),
          ),
          const SizedBox(width: 6),
          Text(
            _wasCorrect ? 'Great job!' : 'Nice try — keep going!',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _wasCorrect
                  ? const Color(0xFF2EAE4E)
                  : const Color(0xFFD17A1F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGame() {
    return Column(
      children: [
        _buildTopBar(),
        _buildStreakBanner(),
        const SizedBox(height: 12),
        _buildQuestionCard(),
        _buildOptions(),
        _buildFeedback(),
      ],
    );
  }

  // ---------------- UI: game over screen ----------------

  Widget _buildGameOver() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            const Text(
              'Awesome work!',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'You collected $_stars stars\nand reached Level $_difficulty.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Color(0xFF666666)),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _restart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'Play Again',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
