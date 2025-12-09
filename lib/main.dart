import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const QuizApp());
}

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: const Color(0xFFF5F3FF),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 18),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/quiz': (context) => const QuizScreen(),
        '/result': (context) => const ResultScreen(),
      },
    );
  }
}

// MODELLO DOMANDA
class TriviaQuestion {
  final String question;
  final String correctAnswer;
  final List<String> allAnswers;

  TriviaQuestion({
    required this.question,
    required this.correctAnswer,
    required this.allAnswers,
  });

  factory TriviaQuestion.fromJson(Map<String, dynamic> json) {
    final incorrect = List<String>.from(json['incorrect_answers'] as List);
    final correct = json['correct_answer'] as String;

    final all = [...incorrect, correct]..shuffle();

    return TriviaQuestion(
      question: json['question'] as String,
      correctAnswer: correct,
      allAnswers: all,
    );
  }
}

// SERVIZIO API OPENTRIVIADB
class TriviaService {
  static const String baseUrl = 'https://opentdb.com/api.php';

  Future<List<TriviaQuestion>> fetchQuestions({
    int amount = 10,
    String difficulty = 'easy',
    String type = 'multiple',
  }) async {
    final uri = Uri.parse(
      '$baseUrl?amount=$amount&difficulty=$difficulty&type=$type',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Errore nel caricamento delle domande');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (data['response_code'] != 0) {
      throw Exception('Errore API: nessuna domanda trovata');
    }

    final results = data['results'] as List;

    return results
        .map((json) => TriviaQuestion.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}

// HOME SCREEN
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    int numberOfQuestions = 10;
    String difficulty = 'easy';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Home'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Benvenuto nel Quiz!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text(
                      'Impostazioni quiz',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Numero domande:'),
                        DropdownButton<int>(
                          value: numberOfQuestions,
                          items: const [
                            DropdownMenuItem(value: 5, child: Text('5')),
                            DropdownMenuItem(value: 10, child: Text('10')),
                            DropdownMenuItem(value: 15, child: Text('15')),
                          ],
                          onChanged: (value) {},
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Difficoltà:'),
                        DropdownButton<String>(
                          value: difficulty,
                          items: const [
                            DropdownMenuItem(value: 'easy', child: Text('Facile')),
                            DropdownMenuItem(value: 'medium', child: Text('Media')),
                            DropdownMenuItem(value: 'hard', child: Text('Difficile')),
                          ],
                          onChanged: (value) {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/quiz',
                  arguments: {
                    'amount': numberOfQuestions,
                    'difficulty': difficulty,
                  },
                );
              },
              child: const Text(
                'Inizia Quiz',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// QUIZ SCREEN
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final TriviaService _service = TriviaService();
  late Future<List<TriviaQuestion>> _futureQuestions;

  int _currentIndex = 0;
  int _score = 0;
  bool _answered = false;
  String? _selectedAnswer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args =
    ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final int amount = args?['amount'] ?? 10;
    final String difficulty = args?['difficulty'] ?? 'easy';

    _futureQuestions =
        _service.fetchQuestions(amount: amount, difficulty: difficulty);
  }

  void _onAnswerSelected(TriviaQuestion question, String answer) {
    if (_answered) return;

    setState(() {
      _answered = true;
      _selectedAnswer = answer;
      if (answer == question.correctAnswer) _score++;
    });

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        if (_currentIndex < _questionsCount - 1) {
          _currentIndex++;
          _answered = false;
          _selectedAnswer = null;
        } else {
          Navigator.pushReplacementNamed(
            context,
            '/result',
            arguments: _score,
          );
        }
      });
    });
  }

  int get _questionsCount => 10;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<TriviaQuestion>>(
        future: _futureQuestions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Errore: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nessuna domanda trovata.'));
          }

          final questions = snapshot.data!;
          final question = questions[_currentIndex];

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(
                  value: (_currentIndex + 1) / questions.length,
                  backgroundColor: Colors.deepPurple.shade100,
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 20),

                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      question.question,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: ListView(
                    children: question.allAnswers.map((answer) {
                      final bool isCorrect = answer == question.correctAnswer;
                      final bool isSelected = answer == _selectedAnswer;

                      Color? color;
                      if (_answered) {
                        if (isCorrect) color = Colors.green;
                        if (isSelected && !isCorrect) color = Colors.red;
                      }

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => _onAnswerSelected(question, answer),
                          child: Text(
                            answer,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// RESULT SCREEN
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final int score = ModalRoute.of(context)!.settings.arguments as int;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Risultato'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.emoji_events,
                size: 100,
                color: Colors.amber,
              ),
              const SizedBox(height: 20),

              const Text(
                'Quiz terminato!',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              Text(
                'Punteggio: $score',
                style: const TextStyle(fontSize: 26),
              ),

              const SizedBox(height: 40),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                        (route) => false,
                  );
                },
                child: const Text(
                  'Torna alla Home',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
