import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:quizmonke/quiz/question_item.dart';
import 'package:quizmonke/quiz/quiz_screen.dart';

class QuestionConnectTerms extends StatefulWidget {
  final QuestionItem questionItem;
  final Function(QuestionResult) onAnswerChecked;

  const QuestionConnectTerms({
    Key? key,
    required this.questionItem,
    required this.onAnswerChecked,
  }) : super(key: key);

  @override
  _QuestionConnectTermsState createState() => _QuestionConnectTermsState();
}

class _Pair {
  String left;
  String right;
  Color color;

  _Pair({required this.left, required this.right, required this.color});
}

class _QuestionConnectTermsState extends State<QuestionConnectTerms> {
  List<_Pair> selectedPairs = [];
  _Pair? currentlySelectedPair;

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
        // Connect Terms
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildColumn(widget.questionItem.leftColumn, "left"),
            _buildColumn(widget.questionItem.rightColumn, "right"),
          ],
        ),
        const SizedBox(height: 20),
        // Check Answer Button
        ElevatedButton(
          onPressed: selectedPairs.isNotEmpty &&
                  selectedPairs.length == widget.questionItem.leftColumn!.length
              ? () {
                  bool isCorrect = _areAnswersCorrect();
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

  Widget _buildColumn(List<String>? terms, String columnType) {
    final double boxWidth = MediaQuery.of(context).size.width *
        0.4; // Adjust the percentage as needed

    final List<String> shuffledTerms = [...terms ?? []];
    shuffledTerms.shuffle();

    return Column(
      children: shuffledTerms.map((term) {
        return GestureDetector(
          onTap: () {
            setState(() {
              final pairToRemove = selectedPairs.firstWhere(
                (pair) =>
                    (pair.left == term && columnType == 'left') ||
                    (pair.right == term && columnType == 'right'),
                orElse: () => _Pair(left: '', right: '', color: Colors.grey),
              );

              if (pairToRemove.left.isNotEmpty ||
                  pairToRemove.right.isNotEmpty) {
                selectedPairs.remove(pairToRemove);
              }

              if (currentlySelectedPair == null ||
                  (currentlySelectedPair!.right.isNotEmpty &&
                      columnType == 'right') ||
                  (currentlySelectedPair!.left.isNotEmpty &&
                      columnType == 'left')) {
                currentlySelectedPair = _Pair(
                    left: columnType == 'left' ? term : '',
                    right: columnType == 'right' ? term : '',
                    color: _generateRandomColor());
              } else if (currentlySelectedPair!.right.isEmpty &&
                  currentlySelectedPair!.left.isNotEmpty &&
                  columnType == 'right') {
                currentlySelectedPair!.right = term;
                selectedPairs.add(currentlySelectedPair!);
                currentlySelectedPair = null;
              } else if (currentlySelectedPair!.left.isEmpty &&
                  currentlySelectedPair!.right.isNotEmpty &&
                  columnType == 'left') {
                currentlySelectedPair!.left = term;
                selectedPairs.add(currentlySelectedPair!);
                currentlySelectedPair = null;
              } else if (currentlySelectedPair!.right == term) {
                currentlySelectedPair!.right = '';
              } else if (currentlySelectedPair!.left == term) {
                currentlySelectedPair!.left = '';
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: _getPairColor(term, columnType),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Container(
                width: boxWidth,
                padding: const EdgeInsets.all(10),
                child: Text(
                  term,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getPairColor(String term, String columnType) {
    if (currentlySelectedPair != null &&
        currentlySelectedPair?.color != null &&
        (columnType == 'left' && term == currentlySelectedPair?.left ||
            columnType == 'right' && term == currentlySelectedPair?.right)) {
      return currentlySelectedPair!.color;
    }
    _Pair? pair = selectedPairs.firstWhere(
      (pair) =>
          (columnType == 'left' && pair.left == term) ||
          (columnType == 'right' && pair.right == term),
      orElse: () => _Pair(left: term, right: '', color: Colors.grey),
    );

    return pair.color;
  }

  Color _generateRandomColor() {
    return Colors.primaries[Random().nextInt(Colors.primaries.length)];
  }

  bool _areAnswersCorrect() {
    Set<String> correctPairs =
        Set.from(widget.questionItem.answer?.split(',') ?? []);

    Set<String> selectedPairStrings = Set.from(
      selectedPairs.map((pair) => '${pair.left}-${pair.right}'),
    );

    return correctPairs.containsAll(selectedPairStrings) &&
        selectedPairStrings.containsAll(correctPairs);
  }
}
