import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:quizmonke/quiz/question_item.dart';

class QuestionFreeText extends StatefulWidget {
  final QuestionItem questionItem;
  final Function(bool) onAnswerChecked;

  const QuestionFreeText({
    Key? key,
    required this.questionItem,
    required this.onAnswerChecked,
  }) : super(key: key);

  @override
  _QuestionFreeTextState createState() => _QuestionFreeTextState();
}

class _QuestionFreeTextState extends State<QuestionFreeText> {
  TextEditingController answerController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text("QuestionFreeText"),
        // Question
        Text(
          widget.questionItem.question ?? '',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        // Free Text Input
        TextFormField(
          controller: answerController,
          decoration: const InputDecoration(
            labelText: 'Your Answer',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        // Check Answer Button
        ElevatedButton(
          onPressed: () => _checkAnswer(),
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

  Future<void> _checkAnswer() async {
    String currentAnswer = answerController.text.trim();
    String correctAnswer = widget.questionItem.answer?.trim() ?? '';

    if (_isLocalMatch(currentAnswer, correctAnswer)) {
      widget.onAnswerChecked(true);
    } else {
      try {
        final HttpsCallableResult<dynamic> result = await FirebaseFunctions
            .instance
            .httpsCallable('check_free_text_answer_fn')
            .call({
          "question": widget.questionItem.question,
          "answer": widget.questionItem.answer,
          "providedAnswer": currentAnswer,
        });

        bool isCorrect = result.data as bool;
        widget.onAnswerChecked(isCorrect);
      } catch (e) {
        print('Error checking answer: $e');
        widget.onAnswerChecked(false); // Assume incorrect if there's an error
      }
    }
  }

  bool _isLocalMatch(String providedAnswer, String correctAnswer) {
    return providedAnswer.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '') ==
        correctAnswer.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
  }
}

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      body: QuestionFreeText(
        questionItem: QuestionItem(
          id: '3',
          type: 'free_text',
          question: 'What is the capital of Italy?',
          answer: 'Rome',
        ),
        onAnswerChecked: (bool isCorrect) {
          print('Answer is correct: $isCorrect');
        },
      ),
    ),
  ));
}
