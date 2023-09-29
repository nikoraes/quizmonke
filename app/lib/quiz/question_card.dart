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
          "${questionItem.question}",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20), // Add some spacing

        // Use a Switch statement to handle different question types
        // Display appropriate UI elements based on the question type
        if (questionItem.type == 'multiple_choice') ...[
          _buildMultipleChoiceQuestion()
        ] /* else if (questionItem.type == 'connect_terms') ...[
          _buildConnectTermsQuestion()
        ] else if (questionItem.type == 'free_text') ...[
          _buildFreeTextQuestion()
        ] */
        else ...[
          InkWell(
            onTap: () {
              onAnswerSelected('');
            },
            child: const Text('Unsupported question type'),
          ),
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
  /*  Widget _buildConnectTermsQuestion() {
    // Create a list of draggable terms for each column
    List<Widget> leftColumnTerms = [];
    List<Widget> rightColumnTerms = [];

    List<String> leftColumn = questionItem.leftColumn ?? [];
    List<String> rightColumn = questionItem.rightColumn ?? [];

    for (final term in leftColumn) {
      leftColumnTerms.add(
        Draggable(
          feedback: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.blue,
              border: Border.all(color: Colors.grey),
            ),
            child: Text(term),
          ),
          childWhenDragging: Container(),
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
            ),
            child: Text(term),
          ),
        ),
      );
    }

    for (final term in rightColumn) {
      rightColumnTerms.add(
        DragTarget(
          onAccept: (Draggable draggable) {
            // Check if the dropped term is the correct answer
            final droppedTerm = draggable.data as String;
            final correctIndex = questionItem.answer?.split(',')[0];
            if (droppedTerm == questionItem.leftColumn[correctIndex]) {
              // The answer is correct
              setState(() {
                // Change the color of both terms to indicate that they are matched
                leftColumnTerms[correctIndex] = Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Text(questionItem.leftColumn[correctIndex]),
                );
                rightColumnTerms[correctIndex] = Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Text(questionItem.rightColumn[correctIndex]),
                );
              });
            } else {
              // The answer is incorrect
              // Do nothing
            }
          },
          builder: (BuildContext context, List<Draggable<Object>?> candidateData, List<dynamic> rejectedData) {  },
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
            ),
            child: Text(term),
          ),
        ),
      );
    }

    // Create a button to check the answer
    final checkAnswerButton = ElevatedButton(
      onPressed: () {
        // Check the user's answer
        final userAnswer = _getConnectedTerms();
        if (userAnswer == questionItem.answer) {
          // The answer is correct
          onAnswerChecked(true);
        } else {
          // The answer is incorrect
          onAnswerChecked(false);
        }
      },
      child: const Text('Check Answer'),
    );

    // Return the UI for the connect_terms question
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: leftColumnTerms,
            ),
            Column(
              children: rightColumnTerms,
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        checkAnswerButton,
      ],
    );
  }

  // Private method to get the list of connected terms
  List<String> _getConnectedTerms() {
    final connectedTerms = [];
    for (var i = 0; i < questionItem.leftColumn.length; i++) {
      connectedTerms.add('$i-${questionItem.answer.split(',')[i]}');
    }
    return connectedTerms;
  } */

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
