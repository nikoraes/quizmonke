import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionItem {
  final String id;
  final String type;
  final String? question;
  final String? answer;
  // final Map<String, String>? multiAnswer;
  final List<String>? choices; // For multiple choice questions
  final List<String>? leftColumn; // For connect_terms questions
  final List<String>? rightColumn; // For connect_terms questions

  QuestionItem({
    required this.id,
    required this.type,
    this.question,
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
        leftColumn: data?['left_column'] is Iterable
            ? List.from(data?['left_column'])
            : null,
        rightColumn: data?['right_column'] is Iterable
            ? List.from(data?['right_column'])
            : null,
        answer: data?['type'] == "connect_terms" &&
                data?['answer'] != null &&
                data?['left_column'] is Iterable &&
                data?['right_column'] is Iterable
            ? transformIndexPairsToTermPairs(List.from(data?['left_column']),
                List.from(data?['right_column']), data?['answer'])
            : data?['answer']);
  }

  Map<String, dynamic> toFirestore() {
    return {
      "type": type,
      "question": question,
      if (choices != null) "choices": choices,
      if (leftColumn != null) "left_column": leftColumn,
      if (rightColumn != null) "right_column": rightColumn,
      if (answer != null)
        "answer": type == "connect_terms" &&
                leftColumn != null &&
                rightColumn != null
            ? transformTermPairsToIndexPairs(leftColumn!, rightColumn!, answer!)
            : answer,
    };
  }
}

String transformIndexPairsToTermPairs(
    List<String> leftColumn, List<String> rightColumn, String originalAnswer) {
  List<String> originalPairs = originalAnswer.split(',');

  List<String> termPairs = originalPairs.map((pair) {
    List<int> indexes = pair.split('-').map(int.parse).toList();

    String leftTerm = leftColumn[indexes[0] - 1];
    String rightTerm = rightColumn[indexes[1] - 1];

    return '$leftTerm-$rightTerm';
  }).toList();

  return termPairs.join(',');
}

String transformTermPairsToIndexPairs(
    List<String> leftColumn, List<String> rightColumn, String originalAnswer) {
  List<String> termPairs = originalAnswer.split(',');

  List<String> indexPairs = termPairs.map((pair) {
    List<String> terms = pair.split('-');

    int leftIndex = leftColumn.indexOf(terms[0]) + 1;
    int rightIndex = rightColumn.indexOf(terms[1]) + 1;

    return '$leftIndex-$rightIndex';
  }).toList();

  return indexPairs.join(',');
}
