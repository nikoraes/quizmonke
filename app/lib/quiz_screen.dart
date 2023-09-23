import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:convert';


class QuizArguments {
  final String topicId;
  final List<QuestionItem> questions;

  QuizArguments(this.topicId, this.questions);
}

class QuestionItem {
  final String id;
  final String type;
  final String question;
  final String? answer;
  // final Map<String, String>? multiAnswer;
  final List<String>? choices; // For multiple choice questions
  final List<String>? leftColumn; // For connect_terms questions
  final List<String>? rightColumn; // For connect_terms questions

  QuestionItem({
    required this.id,
    required this.type,
    required this.question,
    this.answer,
    //this.multiAnswer,
    this.choices, // Add this field for multiple choice questions
    this.leftColumn, // Add this field for connect_terms questions
    this.rightColumn, // Add this field for connect_terms questions
  });

  factory QuestionItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return QuestionItem(
        id: snapshot.id,
        type: data?['type'],
        question: data?['question'],
        choices:
            data?['choices'] is Iterable ? List.from(data?['choices']) : null,
        leftColumn: data?['leftColumn'] is Iterable
            ? List.from(data?['leftColumn'])
            : null,
        rightColumn: data?['rightColumn'] is Iterable
            ? List.from(data?['rightColumn'])
            : null,
        answer: data?['answer']);
  }

  Map<String, dynamic> toFirestore() {
    return {
      "type": type,
      "question": question,
      if (choices != null) "choices": choices,
      if (leftColumn != null) "leftColumn": leftColumn,
      if (rightColumn != null) "rightColumn": rightColumn,
      if (answer != null) "answer": answer,
    };
  }
}

class QuizScreen extends StatefulWidget {
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

  void checkAnswer(String selectedAnswer) {
    final currentQuestion = questions[currentIndex];

    if (currentQuestion.answer == null) return;

    if (currentQuestion.type == 'multiple_choice' ||
        currentQuestion.type == 'free_text') {
      if (selectedAnswer == currentQuestion.answer) {
        // Correct answer logic
        // Show a congratulatory screen and move to the next question.
        print('correct - $selectedAnswer - ${currentQuestion.answer}');
        showCongratulatoryScreen(context);
      } else {
        print('wrong - $selectedAnswer - ${currentQuestion.answer}');
        // Incorrect answer logic
        // Show the correct answer and allow the user to continue.
        // if (currentQuestion.answer != null) showIncorrectAnswerScreen(currentQuestion.answer);
      }
    } else if (currentQuestion.type == 'connect_terms') {
      // Handle connect_terms type question here
      // Compare selected answers with the correct answers
      // Show congratulatory screen or incorrect answer screen accordingly
    }
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

  void showIncorrectAnswerScreen(String correctAnswer) {
    // Implement the incorrect answer screen logic here
    // You can show the correct answer and provide an option to continue.
  }

  void showIncorrectMultiAnswerScreen(Map<String, String> correctAnswer) {
    // Implement the incorrect answer screen logic here
    // You can show the correct answer and provide an option to continue.
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as QuizArguments;
    questions = args.questions;

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz ${args.topicId} - $currentIndex'),
      ),
      body: currentIndex < questions.length
          ? QuestionCard(
              questionItem: questions[currentIndex],
              onAnswerSelected: checkAnswer,
            )
          : // Show a final screen or summary of results when all questions are answered.
          const Center(
              child: Text('Quiz completed!'),
            ),
    );
  }
}

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
    return Column(
      children: questionItem.choices?.map((choice) {
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
    );
  }

  // Helper method to build UI for connect_terms questions
  Widget _buildConnectTermsQuestion() {
    // Implement the UI for connect_terms questions here
    // You can use draggable lists to match terms.
    // Make sure to handle user interactions properly and call onAnswerSelected when appropriate.
    return const Text('Connect the terms question');
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

const jsonString = '''
[
    {
      "type": "multiple_choice",
      "question": "Wat zijn de weerelementen die in weerberichten worden besproken?",
      "choices": ["Temperatuur, luchtdruk, windrichting", "Temperatuur, neerslag, luchtdruk", "Windrichting, windsnelheid, neerslag"],
      "answer": "Temperatuur, neerslag, luchtdruk"
    },
    {
      "type": "connect_terms",
      "question": "Verbind de weerelementen met hun eenheden:",
      "left_column": ["Temperatuur", "Neerslag", "Luchtdruk"],
      "right_column": ["°C (graden Celsius)", "mm (millimeter)", "hPa (hectopascal)"],
      "multi_answer": {"Temperatuur": "°C (graden Celsius)", "Neerslag": "mm (millimeter)", "Luchtdruk": "hPa (hectopascal)"}
    },
    {
      "type": "free_text",
      "question": "Wat is de toestand van de lucht op een bepaalde plaats op een bepaald ogenblik?",
      "answer": "Het weer"
    },
    {
      "type": "multiple_choice",
      "question": "Hoe wordt de temperatuur op een weerkaart voorgesteld?",
      "choices": ["Met lijnen genaamd isobaren", "Met lijnen genaamd isothermen", "Met lijnen genaamd isohyeten"],
      "answer": "Met lijnen genaamd isothermen"
    },
    {
      "type": "connect_terms",
      "question": "Verbind de juiste termen met hun betekenis:",
      "left_column": ["Windrichting", "Windsnelheid", "Neerslag"],
      "right_column": ["Windrichting aangeduid met een pijl", "Snelheid van de wind in km/u", "Hoeveelheid neerslag"],
      "multi_answer": {"Windrichting": "Windrichting aangeduid met een pijl", "Windsnelheid": "Snelheid van de wind in km/u", "Neerslag": "Hoeveelheid neerslag"}
    },
    {
      "type": "multiple_choice",
      "question": "Wat is een normale luchtdrukwaarde, en hoe wordt een hogere druk aangeduid?",
      "choices": ["1 000 hPa, Hoge druk", "1 013 hPa, Lage druk", "1 013 hPa, Hoge druk"],
      "answer": "1 013 hPa, Hoge druk"
    },
    {
      "type": "connect_terms",
      "question": "Verbind de juiste termen met hun betekenis:",
      "left_column": ["Windroos", "Isothermen", "Isohyeten"],
      "right_column": ["Aanduiding van windrichting met pijlen", "Lijnen die temperatuur op een kaart aangeven", "Lijnen die neerslag op een kaart aangeven"],
      "multi_answer": {"Windroos": "Aanduiding van windrichting met pijlen", "Isothermen": "Lijnen die temperatuur op een kaart aangeven", "Isohyeten": "Lijnen die neerslag op een kaart aangeven"}
    },
    {
      "type": "free_text",
      "question": "Hoe ontstaat wind volgens de tekst?",
      "answer": "Wind ontstaat door een verschil in luchtdruk."
    },
    {
      "type": "multiple_choice",
      "question": "Hoe wordt de windsnelheid beïnvloed door de afstand tussen de isobaren op een weerkaart?",
      "choices": ["Hoe dichter de isobaren bij elkaar liggen, hoe groter de windsnelheid.", "Hoe verder de isobaren uit elkaar liggen, hoe groter de windsnelheid.", "Isobaren hebben geen invloed op windsnelheid."],
      "answer": "Hoe dichter de isobaren bij elkaar liggen, hoe groter de windsnelheid."
    },
    {
      "type": "free_text",
      "question": "Wat betekent een zuidwestenwind?",
      "answer": "Een zuidwestenwind komt uit het zuidwesten."
    }
  ]
''';
final List<dynamic> jsonList = json.decode(jsonString);

/* 
Generate the code for a quiz screen in Flutter (Dart). The screen will receive a list of questions and answers (List<QuestionItem>). For each question, a screen should be displayed that shows the question in a suitable and playful manner. There are multiple types of questions (3 in this sample) and depending on the type of question, it should be shown in a different way (it could look similar to DuoLingo for example). When the user selects an answer (or fills it in in case of a free text answer), the answer should be verified. If the answer is correct, the user will see a screen to congratulate the user, and continue to the next question. In case it's wrong, the right answer should be shown and the user can continue as well. When all questions are answered, the questions where the user gave a wrong answer should be asked again.

Here's an example of an input for those questions:
[
    {
      "type": "multiple_choice",
      "question": "Wat zijn de weerelementen die in weerberichten worden besproken?",
      "choices": ["Temperatuur, luchtdruk, windrichting", "Temperatuur, neerslag, luchtdruk", "Windrichting, windsnelheid, neerslag"],
      "answer": "Temperatuur, neerslag, luchtdruk"
    },
    {
      "type": "connect_terms",
      "question": "Verbind de weerelementen met hun eenheden:",
      "left_column": ["Temperatuur", "Neerslag", "Luchtdruk"],
      "right_column": ["°C (graden Celsius)", "mm (millimeter)", "hPa (hectopascal)"],
      "answer": {"Temperatuur": "°C (graden Celsius)", "Neerslag": "mm (millimeter)", "Luchtdruk": "hPa (hectopascal)"}
    },
    {
      "type": "free_text",
      "question": "Wat is de toestand van de lucht op een bepaalde plaats op een bepaald ogenblik?",
      "answer": "Het weer"
    },
    {
      "type": "multiple_choice",
      "question": "Hoe wordt de temperatuur op een weerkaart voorgesteld?",
      "choices": ["Met lijnen genaamd isobaren", "Met lijnen genaamd isothermen", "Met lijnen genaamd isohyeten"],
      "answer": "Met lijnen genaamd isothermen"
    },
    {
      "type": "connect_terms",
      "question": "Verbind de juiste termen met hun betekenis:",
      "left_column": ["Windrichting", "Windsnelheid", "Neerslag"],
      "right_column": ["Windrichting aangeduid met een pijl", "Snelheid van de wind in km/u", "Hoeveelheid neerslag"],
      "answer": {"Windrichting": "Windrichting aangeduid met een pijl", "Windsnelheid": "Snelheid van de wind in km/u", "Neerslag": "Hoeveelheid neerslag"}
    },
    {
      "type": "multiple_choice",
      "question": "Wat is een normale luchtdrukwaarde, en hoe wordt een hogere druk aangeduid?",
      "choices": ["1 000 hPa, Hoge druk", "1 013 hPa, Lage druk", "1 013 hPa, Hoge druk"],
      "answer": "1 013 hPa, Hoge druk"
    },
    {
      "type": "connect_terms",
      "question": "Verbind de juiste termen met hun betekenis:",
      "left_column": ["Windroos", "Isothermen", "Isohyeten"],
      "right_column": ["Aanduiding van windrichting met pijlen", "Lijnen die temperatuur op een kaart aangeven", "Lijnen die neerslag op een kaart aangeven"],
      "answer": {"Windroos": "Aanduiding van windrichting met pijlen", "Isothermen": "Lijnen die temperatuur op een kaart aangeven", "Isohyeten": "Lijnen die neerslag op een kaart aangeven"}
    },
    {
      "type": "free_text",
      "question": "Hoe ontstaat wind volgens de tekst?",
      "answer": "Wind ontstaat door een verschil in luchtdruk."
    },
    {
      "type": "multiple_choice",
      "question": "Hoe wordt de windsnelheid beïnvloed door de afstand tussen de isobaren op een weerkaart?",
      "choices": ["Hoe dichter de isobaren bij elkaar liggen, hoe groter de windsnelheid.", "Hoe verder de isobaren uit elkaar liggen, hoe groter de windsnelheid.", "Isobaren hebben geen invloed op windsnelheid."],
      "answer": "Hoe dichter de isobaren bij elkaar liggen, hoe groter de windsnelheid."
    },
    {
      "type": "free_text",
      "question": "Wat betekent een zuidwestenwind?",
      "answer": "Een zuidwestenwind komt uit het zuidwesten."
    }
  ]
 */
