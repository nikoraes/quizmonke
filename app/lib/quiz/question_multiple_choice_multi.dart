import 'package:flutter/material.dart';

import 'package:quizmonke/quiz/question_item.dart';

class QuestionMultipleChoiceMulti extends StatefulWidget {
  final QuestionItem questionItem;
  final Function(bool) onAnswerChecked;

  const QuestionMultipleChoiceMulti({
    Key? key,
    required this.questionItem,
    required this.onAnswerChecked,
  }) : super(key: key);

  @override
  _QuestionMultipleChoiceMultiState createState() =>
      _QuestionMultipleChoiceMultiState();
}

class _QuestionMultipleChoiceMultiState
    extends State<QuestionMultipleChoiceMulti> {
  List<String> selectedAnswers = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text("QuestionMultipleChoiceMulti"),
        // Question
        Text(
          widget.questionItem.question ?? '',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        // Choices
        Column(
          children: widget.questionItem.choices?.map((choice) {
                bool isSelected = selectedAnswers.contains(choice);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedAnswers.remove(choice);
                      } else {
                        selectedAnswers.add(choice);
                      }
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.grey,
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
          onPressed: selectedAnswers.isNotEmpty
              ? () {
                  bool isCorrect = _areAnswersCorrect();
                  widget.onAnswerChecked(isCorrect);
                }
              : null,
          child: const Text('Check Answer'),
        ),
        // Skip Button
        TextButton(
          onPressed: () {
            widget.onAnswerChecked(false);
          },
          child: const Text('Skip'),
        ),
      ],
    );
  }

  bool _areAnswersCorrect() {
    List<String> correctAnswers =
        widget.questionItem.answer?.split(',').map((e) => e.trim()).toList() ??
            [];

    if (selectedAnswers.length != correctAnswers.length) {
      return false;
    }

    Set<String> selectedSet = Set.from(selectedAnswers);
    Set<String> correctSet = Set.from(correctAnswers);

    return selectedSet.containsAll(correctSet) &&
        correctSet.containsAll(selectedSet);
  }
}
