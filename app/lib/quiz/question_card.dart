import 'package:flutter/material.dart';

import 'package:quizmonke/quiz/question_item.dart';

class QuestionCard extends StatelessWidget {
  const QuestionCard(
      {super.key, required this.questionItem, required this.onAnswerSelected});

  final QuestionItem questionItem;
  final Function(String) onAnswerSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          questionItem.question,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20), // Add some spacing

        // Use a Switch statement to handle different question types
        // Display appropriate UI elements based on the question type
        if (questionItem.type == 'multiple_choice') ...[
          _buildMultipleChoiceQuestion()
        ] else if (questionItem.type == 'connect_terms') ...[
          _buildConnectTermsQuestion()
        ] else if (questionItem.type == 'free_text') ...[
          _buildFreeTextQuestion()
        ] else ...[
          const Text('Unsupported question type')
        ],
      ],
    );
  }

  // Helper method to build UI for multiple choice questions
  Widget _buildMultipleChoiceQuestion() {
    return Column(children: [
      ...questionItem.choices?.map((choice) {
            return RadioListTile(
              title: Text(choice),
              value: choice,
              groupValue: null, // You need to handle this value properly
              onChanged: (value) {
                if (value != null) onAnswerSelected(value);
              },
            );
          }).toList() ??
          [],

/*       TextButton(
        onPressed: () {
        },
        child: const Text('Check'),
        
      ), */
    ]);
  }

  // Helper method to build UI for connect_terms questions
  Widget _buildConnectTermsQuestion() {
    // Implement the UI for connect_terms questions here
    // You can use draggable lists to match terms.
    // Make sure to handle user interactions properly and call onAnswerSelected when appropriate.
    return Text('Connect the terms question - ${questionItem.question}');
  }

  // Helper method to build UI for free text questions
  Widget _buildFreeTextQuestion() {
    return TextField(
      onChanged: (value) {
        // You can track user input here and call onAnswerSelected when needed.
      },
      decoration: const InputDecoration(
        hintText: 'Type your answer here',
      ),
    );
  }
}
