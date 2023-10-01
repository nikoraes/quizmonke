import 'package:flutter/material.dart';
import 'package:quizmonke/quiz/question_connect_terms.dart';
import 'package:quizmonke/quiz/question_free_text.dart';

import 'package:quizmonke/quiz/question_item.dart';
import 'package:quizmonke/quiz/question_multiple_choice.dart';
import 'package:quizmonke/quiz/question_multiple_choice_multi.dart';

class QuizArguments {
  final String topicId;
  final String topicName;
  final List<QuestionItem> questions;

  QuizArguments(this.topicId, this.topicName, this.questions);
}

class QuizScreen extends StatefulWidget {
  // TODO: we should probably have the topic id as a param and retrieve all questions here
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
      BuildContext parentContext, QuestionItem questionItem) {
    // Show dialog
    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Bluh!'),
          content: Text(
              'Your answer is wrong! The correct answer is ${questionItem.answer}'),
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

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as QuizArguments;
    questions = args.questions;

    void onAnswerChecked(QuestionItem questionItem, bool answerCorrect) {
      if (answerCorrect) {
        showCongratulatoryScreen(context);
      } else {
        // Add the question to the end again
        // questions.add(questionItem);
        showIncorrectAnswerScreen(context, questionItem);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz ${args.topicName} - $currentIndex'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: (currentIndex < questions.length)
            ? _buildQuestion(
                ValueKey(questions[currentIndex]), questions[currentIndex],
                (correct) {
                onAnswerChecked(questions[currentIndex], correct);
              })
            : const Center(
                child: Text('Quiz completed!'),
              ),
      ),
    );
  }
}

Widget _buildQuestion(
    Key key, QuestionItem questionItem, Function(bool) onAnswerChecked) {
  if (questionItem.type == "multiple_choice") {
    return QuestionMultipleChoice(
        key: key, questionItem: questionItem, onAnswerChecked: onAnswerChecked);
  } else if (questionItem.type == "multiple_choice_multi") {
    return QuestionMultipleChoiceMulti(
        key: key, questionItem: questionItem, onAnswerChecked: onAnswerChecked);
  } else if (questionItem.type == "connect_terms") {
    return QuestionConnectTerms(
        key: key, questionItem: questionItem, onAnswerChecked: onAnswerChecked);
  } else if (questionItem.type == "free_text") {
    return QuestionFreeText(
        key: key, questionItem: questionItem, onAnswerChecked: onAnswerChecked);
  } else {
    return InkWell(
      onTap: () {
        onAnswerChecked(false);
      },
      child: Text('Unsupported question type: ${questionItem.type}'),
    );
  }
}
