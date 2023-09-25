import 'package:cloud_firestore/cloud_firestore.dart';

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
