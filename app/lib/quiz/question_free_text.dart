import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:quizmonke/quiz/question_item.dart';
import 'package:quizmonke/quiz/quiz_screen.dart';

class QuestionFreeText extends StatefulWidget {
  final String topicId;
  final QuestionItem questionItem;
  final Function(QuestionResult) onAnswerChecked;

  const QuestionFreeText({
    Key? key,
    required this.topicId,
    required this.questionItem,
    required this.onAnswerChecked,
  }) : super(key: key);

  @override
  State<QuestionFreeText> createState() => _QuestionFreeTextState();
}

class _QuestionFreeTextState extends State<QuestionFreeText> {
  TextEditingController answerController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Question
        Text(
          widget.questionItem.question ?? '',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        // Free Text Input
        TextFormField(
          controller: answerController,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.yourAnswer,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        // Check Answer Button
        ElevatedButton(
          onPressed: () => _checkAnswer(),
          child: Text(AppLocalizations.of(context)!.checkAnswer),
        ),
        // Skip Button
        TextButton(
          onPressed: () {
            widget.onAnswerChecked(QuestionResult.skipped);
          },
          child: Text(AppLocalizations.of(context)!.skip),
        ),
      ],
    );
  }

  Future<void> _checkAnswer() async {
    String currentAnswer = answerController.text.trim();
    String correctAnswer = widget.questionItem.answer?.trim() ?? '';

    if (_isLocalMatch(currentAnswer, correctAnswer)) {
      widget.onAnswerChecked(QuestionResult.correct);
    } else {
      try {
        final HttpsCallableResult<dynamic> result = await FirebaseFunctions
            .instance
            .httpsCallable('check_answer_free_text_fn')
            .call({
          "topicId": widget.topicId,
          "question": widget.questionItem.question,
          "answer": widget.questionItem.answer,
          "providedAnswer": currentAnswer,
        });

        if (result.data == "true") {
          widget.onAnswerChecked(QuestionResult.correct);
        } else {
          widget.onAnswerChecked(QuestionResult.wrong);
        }
        widget.onAnswerChecked(QuestionResult.correct);
      } catch (e) {
        print('Error checking answer: $e');
        widget.onAnswerChecked(
            QuestionResult.wrong); // Assume incorrect if there's an error
      }
    }
  }

  bool _isLocalMatch(String providedAnswer, String correctAnswer) {
    return providedAnswer.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '') ==
        correctAnswer.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
  }
}
