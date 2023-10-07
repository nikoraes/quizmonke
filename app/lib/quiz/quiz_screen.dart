import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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

enum QuestionResult { correct, wrong, skipped }

class QuizScreen extends StatefulWidget {
  // TODO: we should probably have the topic id as a param and retrieve all questions here
  static String routeName = '/quiz';
  const QuizScreen({super.key});

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late String topicId;
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
          title: Text(AppLocalizations.of(context)!.congratulations),
          content: Text(AppLocalizations.of(context)!.answerCorrect),
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
              child: Text(AppLocalizations.of(context)!.nextQuestion),
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
          title: Text(AppLocalizations.of(context)!.bluh),
          content: Text(AppLocalizations.of(context)!
              .answerWrong('${questionItem.answer}')),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(parentContext);
              },
              child: Text(AppLocalizations.of(context)!.tryAgain),
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
              child: Text(AppLocalizations.of(context)!.nextQuestion),
            ),
          ],
        );
      },
    );
  }

  void showSkippedAnswerScreen(
      BuildContext parentContext, QuestionItem questionItem) {
    // Show dialog
    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.skipped),
          content: Text(AppLocalizations.of(context)!
              .answerSkipped('${questionItem.answer}')),
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
              child: Text(AppLocalizations.of(context)!.nextQuestion),
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
    topicId = args.topicId;

    int numberCorrect = 0;
    int numberWrong = 0;
    int numberSkipped = 0;

    void onAnswerChecked(QuestionItem questionItem, QuestionResult result) {
      if (result == QuestionResult.correct) {
        showCongratulatoryScreen(context);
        numberCorrect++;
      } else if (result == QuestionResult.skipped) {
        showSkippedAnswerScreen(context, questionItem);
        numberSkipped++;
      } else {
        // Add the question to the end again
        questions.add(questionItem);
        showIncorrectAnswerScreen(context, questionItem);
        numberWrong++;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${args.topicName} - $currentIndex'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: (currentIndex < questions.length)
            ? _buildQuestion(context, ValueKey(questions[currentIndex]),
                topicId, questions[currentIndex], (correct) {
                onAnswerChecked(questions[currentIndex], correct);
              })
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context)!.quizCompleted,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppLocalizations.of(context)!.resultsOverview,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                      '${AppLocalizations.of(context)!.correctLabel} $numberCorrect'),
                  Text(
                      '${AppLocalizations.of(context)!.wrongLabel} $numberWrong'),
                  Text(
                      '${AppLocalizations.of(context)!.skippedLabel} $numberSkipped'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Add logic to generate more questions
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: Text(AppLocalizations.of(context)!.generateMore),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: Text(AppLocalizations.of(context)!.back),
                  ),
                ],
              ),
      ),
    );
  }
}

Widget _buildQuestion(BuildContext context, Key key, String topicId,
    QuestionItem questionItem, Function(QuestionResult) onAnswerChecked) {
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
        key: key,
        topicId: topicId,
        questionItem: questionItem,
        onAnswerChecked: onAnswerChecked);
  } else {
    return InkWell(
      onTap: () {
        onAnswerChecked(QuestionResult.skipped);
      },
      child: Text(
          AppLocalizations.of(context)!.unsupportedQuestion(questionItem.type)),
    );
  }
}
