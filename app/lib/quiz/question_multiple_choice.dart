import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:quizmonke/quiz/question_item.dart';
import 'package:quizmonke/quiz/quiz_screen.dart';

class QuestionMultipleChoice extends StatefulWidget {
  final QuestionItem questionItem;
  final Function(QuestionResult) onAnswerChecked;

  const QuestionMultipleChoice(
      {super.key, required this.questionItem, required this.onAnswerChecked});

  @override
  _QuestionMultipleChoiceState createState() => _QuestionMultipleChoiceState();
}

class _QuestionMultipleChoiceState extends State<QuestionMultipleChoice> {
  String? currentAnswer;

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
        // Choices
        Column(
          children: widget.questionItem.choices?.map((choice) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      currentAnswer = choice;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          currentAnswer == choice ? Colors.blue : Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      choice,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              }).toList() ??
              [],
        ),
        const SizedBox(height: 20),
        // Check Answer Button
        ElevatedButton(
          onPressed: currentAnswer != null
              ? () {
                  bool isCorrect = currentAnswer == widget.questionItem.answer;
                  widget.onAnswerChecked(isCorrect
                      ? QuestionResult.correct
                      : QuestionResult.wrong);
                }
              : null,
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
}
