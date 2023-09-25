import 'package:flutter/material.dart';

import 'package:quizmonke/quiz/question_card.dart';
import 'package:quizmonke/quiz/question_item.dart';

class QuizArguments {
  final String topicId;
  final List<QuestionItem> questions;

  QuizArguments(this.topicId, this.questions);
}

class QuizScreen extends StatefulWidget {
  static String routeName = '/quiz';
  const QuizScreen({super.key});

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<QuestionItem> questions;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  void checkAnswer(String selectedAnswer) {
    final currentQuestion = questions[currentIndex];
    print(
        'checkAnswer - $selectedAnswer - $currentIndex - ${questions.map((q) => q.answer)} - ${currentQuestion.answer}');

    if (currentQuestion.answer == null) return;

    if (currentQuestion.type == 'multiple_choice' ||
        currentQuestion.type == 'free_text') {
      if (selectedAnswer == currentQuestion.answer) {
        // Correct answer logic
        // Show a congratulatory screen and move to the next question.
        print('correct - $selectedAnswer - ${currentQuestion.answer}');
        showCongratulatoryScreen(context);
      } else {
        print('wrong - $selectedAnswer - ${currentQuestion.answer}');
        showIncorrectAnswerScreen(context, '${currentQuestion.answer}');
        // Incorrect answer logic
        // Show the correct answer and allow the user to continue.
        // if (currentQuestion.answer != null) showIncorrectAnswerScreen(currentQuestion.answer);
      }
    } else if (currentQuestion.type == 'connect_terms') {
      // Handle connect_terms type question here
      // Compare selected answers with the correct answers
      // Show congratulatory screen or incorrect answer screen accordingly
    }
  }

  void showCongratulatoryScreen(BuildContext parentContext) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Congratulations!'),
          content: const Text('Your answer is correct!'),
          actions: [
            TextButton(
              onPressed: () {
                print('currentIndex: $currentIndex / ${questions.length}');
                // Move to the next question if there are more questions
                if (currentIndex < questions.length - 1) {
                } else {
                  // Handle the case when all questions are completed.
                  // You can navigate to a summary screen or perform other actions.
                  // For now, just print a message.
                  print('All questions completed.');
                }
                setState(() {
                  currentIndex++; // Move to the next question
                });
                Navigator.pop(parentContext);
              },
              child: const Text('Next Question'),
            ),
          ],
        );
      },
    );
  }

  void showIncorrectAnswerScreen(
      BuildContext parentContext, String correctAnswer) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Bluh!'),
          content: Text(
              'Your answer is wrong! The correct answer is $correctAnswer'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(parentContext);
              },
              child: const Text('Try again'),
            ),
            TextButton(
              onPressed: () {
                print('currentIndex: $currentIndex / ${questions.length}');
                // Move to the next question if there are more questions
                if (currentIndex < questions.length - 1) {
                } else {
                  // Handle the case when all questions are completed.
                  // You can navigate to a summary screen or perform other actions.
                  // For now, just print a message.
                  print('All questions completed.');
                }
                setState(() {
                  currentIndex++; // Move to the next question
                });
                Navigator.pop(parentContext);
              },
              child: const Text('Next Question'),
            ),
          ],
        );
      },
    );
  }

  void showIncorrectMultiAnswerScreen(Map<String, String> correctAnswer) {
    // Implement the incorrect answer screen logic here
    // You can show the correct answer and provide an option to continue.
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as QuizArguments;
    questions = args.questions;

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz ${args.topicId} - $currentIndex'),
      ),
      body: currentIndex < questions.length
          ? QuestionCard(
              questionItem: questions[currentIndex],
              onAnswerSelected: checkAnswer,
            )
          : // Show a final screen or summary of results when all questions are answered.
          const Center(
              child: Text('Quiz completed!'),
            ),
    );
  }
}
