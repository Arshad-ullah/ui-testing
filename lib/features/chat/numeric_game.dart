// number_logic_game.dart
//
// A self-contained "Number Logic" mini-game for a kids' IQ-training app.
// Drop into lib/games/number_logic_game.dart and push `const NumberLogicGame()`.
//
// FIXES in this version (vs. the previous draft):
//  1. Answer cards now have a stable, question-unique Key. Previously Flutter
//     reused the same widget slot across questions (since GridView children
//     had no Key), so on the 2nd+ question the AnimatedContainer sometimes
//     kept old colors/text mid-transition instead of resetting cleanly.
//  2. Added an `_answering` lock so rapid double-taps can't fire two answers
//     at once and desync state (this looked like a "hang").
//  3. Wrapped the question + options in a SingleChildScrollView so a long
//     prompt (e.g. big multiplication numbers) can't overflow and silently
//     break layout on smaller screens.
//  4. Timer-based delay (cancelable) instead of a bare `Future.delayed`, so
//     leftover timers from a previous question can never fire late and
//     corrupt state after rapid taps.
//  5. Animation now uses `addPostFrameCallback` so `forward(from: 0)` never
//     races with the widget tree still being built.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ---------------------------------------------------------------------
/// QUESTION MODEL
/// ---------------------------------------------------------------------

enum QuestionType { sequence, arithmetic }

class NumberQuestion {
  final QuestionType type;
  final String prompt;
  final int answer;
  final List<int> options;
  final int id; // unique per generated question, used for Keys & animations

  NumberQuestion({
    required this.type,
    required this.prompt,
    required this.answer,
    required this.options,
    required this.id,
  });
}

/// ---------------------------------------------------------------------
/// QUESTION GENERATOR (adaptive difficulty)
/// ---------------------------------------------------------------------

class QuestionGenerator {
  final Random _rng = Random();
  int _counter = 0;

  NumberQuestion generate(int difficulty) {
    final useSequence = _rng.nextBool();
    return useSequence
        ? _generateSequence(difficulty)
        : _generateArithmetic(difficulty);
  }

  NumberQuestion _generateSequence(int difficulty) {
    final maxStep = 1 + (difficulty / 2).ceil();
    int step = 1 + _rng.nextInt(maxStep);
    final descending = difficulty > 3 && _rng.nextBool();
    if (descending) step = -step;

    final start = 1 + _rng.nextInt(5 + difficulty * 2);
    const length = 4;
    final seq = List<int>.generate(length, (i) => start + step * i);
    final answer = start + step * length;

    final opSymbol = step >= 0 ? '+' : '−';
    final opAbs = step.abs();
    final buffer = StringBuffer();
    for (var i = 0; i < seq.length; i++) {
      buffer.write(seq[i]);
      buffer.write('  $opSymbol$opAbs  ');
    }
    buffer.write('?');
    final prompt = buffer.toString();
    final options = _buildOptions(answer, spread: step.abs().clamp(1, 12));

    return NumberQuestion(
      type: QuestionType.sequence,
      prompt: prompt,
      answer: answer,
      options: options,
      id: _counter++,
    );
  }

  NumberQuestion _generateArithmetic(int difficulty) {
    final ops = difficulty < 3 ? ['+', '-'] : ['+', '-', '×'];
    final op = ops[_rng.nextInt(ops.length)];

    int a, b, answer;
    final maxVal = 5 + difficulty * 3;

    switch (op) {
      case '+':
        a = 1 + _rng.nextInt(maxVal);
        b = 1 + _rng.nextInt(maxVal);
        answer = a + b;
        break;
      case '-':
        a = 1 + _rng.nextInt(maxVal) + 5;
        b = 1 + _rng.nextInt(a);
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
      id: _counter++,
    );
  }

  List<int> _buildOptions(int answer, {int spread = 3}) {
    final set = <int>{answer};
    var guard = 0;
    while (set.length < 4 && guard < 200) {
      guard++;
      final delta = (1 + _rng.nextInt(spread)) * (_rng.nextBool() ? 1 : -1);
      final candidate = answer + delta;
      if (candidate >= 0) set.add(candidate);
    }
    // Safety net: if we somehow couldn't fill 4 unique options, pad simply.
    var filler = answer + 100;
    while (set.length < 4) {
      set.add(filler++);
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
  bool _answering = false; // tap-lock to prevent double answers / races

  Timer? _advanceTimer;

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
    _question = _generator.generate(_difficulty);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _promptController.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _promptController.dispose();
    super.dispose();
  }

  void _nextQuestion() {
    if (!mounted) return;
    setState(() {
      _question = _generator.generate(_difficulty);
      _selectedOption = null;
      _showFeedback = false;
      _answering = false;
    });
    _promptController.forward(from: 0);
  }

  void _restart() {
    _advanceTimer?.cancel();
    setState(() {
      _difficulty = 2;
      _streak = 0;
      _stars = 0;
      _lives = 3;
      _gameOver = false;
      _answering = false;
    });
    _nextQuestion();
  }

  void _onAnswer(int option) {
    // Lock out further taps until this question fully resolves.
    if (_showFeedback || _gameOver || _answering) return;

    final correct = option == _question.answer;
    HapticFeedback.lightImpact();

    setState(() {
      _answering = true;
      _selectedOption = option;
      _showFeedback = true;
      _wasCorrect = correct;
    });

    if (correct) {
      _streak++;
      _stars++;
      if (_streak % 2 == 0) {
        _difficulty = min(10, _difficulty + 1);
      }
    } else {
      _streak = 0;
      _lives--;
      _difficulty = max(1, _difficulty - 1);
    }

    _advanceTimer?.cancel();
    _advanceTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_lives <= 0) {
        setState(() => _gameOver = true);
      } else {
        _nextQuestion();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _gameOver ? _buildGameOver() : _buildGame()),
    );
  }

  // ---------------- UI: top bar ----------------

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
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
      key: ValueKey('card_${_question.id}'),
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
          mainAxisSize: MainAxisSize.min,
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
            // FittedBox prevents overflow if a prompt is unusually wide
            // (e.g. large multiplication results at high difficulty).
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _question.prompt,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
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
        // Unique key per question so the whole grid (and its children)
        // is rebuilt fresh instead of Flutter trying to diff/reuse old
        // AnimatedContainers from the previous question.
        key: ValueKey('grid_${_question.id}'),
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
            // Unique key per option card within this question.
            key: ValueKey('opt_${_question.id}_$opt'),
            onTap: () => _onAnswer(opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
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
    // SingleChildScrollView guards against overflow on small screens or
    // unusually long prompts — previously this could silently break layout
    // and look like the UI had "frozen" on certain questions.
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildTopBar(),
          _buildStreakBanner(),
          const SizedBox(height: 12),
          _buildQuestionCard(),
          _buildOptions(),
          _buildFeedback(),
          const SizedBox(height: 12),
        ],
      ),
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
