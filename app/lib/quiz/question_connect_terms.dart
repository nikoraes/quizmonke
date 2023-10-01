import 'package:flutter/material.dart';
import 'package:quizmonke/quiz/question_item.dart';

class QuestionConnectTerms extends StatefulWidget {
  final QuestionItem questionItem;
  final Function(bool) onAnswerChecked;

  const QuestionConnectTerms({
    Key? key,
    required this.questionItem,
    required this.onAnswerChecked,
  }) : super(key: key);

  @override
  _QuestionConnectTermsState createState() => _QuestionConnectTermsState();
}

class _QuestionConnectTermsState extends State<QuestionConnectTerms> {
  List<String> selectedLeftTerms = [];
  List<String> selectedRightTerms = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text("QuestionConnectTerms"),
        // Question
        Text(
          widget.questionItem.question ?? '',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        ...widget.questionItem.leftColumn != null
            ? widget.questionItem.leftColumn!.map(
                (e) => Text(e),
              )
            : [],
        ...widget.questionItem.rightColumn != null
            ? widget.questionItem.rightColumn!.map(
                (e) => Text(e),
              )
            : [],
        // Connect Terms
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildColumn(widget.questionItem.leftColumn, selectedLeftTerms),
            _buildColumn(widget.questionItem.rightColumn, selectedRightTerms),
          ],
        ),
        const SizedBox(height: 20),
        // Check Answer Button
        ElevatedButton(
          onPressed: selectedLeftTerms.isNotEmpty &&
                  selectedRightTerms.isNotEmpty &&
                  selectedLeftTerms.length == selectedRightTerms.length
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

  Widget _buildColumn(List<String>? terms, List<String> selectedTerms) {
    return Column(
      children: terms?.map((term) {
            bool isSelected = selectedTerms.contains(term);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    selectedTerms.remove(term);
                  } else {
                    selectedTerms.add(term);
                  }
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.grey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  term,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
          }).toList() ??
          [],
    );
  }

  bool _areAnswersCorrect() {
    List<String> correctPairs = widget.questionItem.answer?.split(',') ?? [];

    Set<String> selectedPairs = Set.from(
      List.generate(selectedLeftTerms.length, (index) {
        return '${selectedLeftTerms[index]}-${selectedRightTerms[index]}';
      }),
    );

    return Set.from(correctPairs).containsAll(selectedPairs) &&
        Set.from(selectedPairs).containsAll(correctPairs);
  }
}
