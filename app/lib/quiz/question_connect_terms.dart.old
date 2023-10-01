import 'package:flutter/material.dart';
import 'package:quizmonke/quiz/question_item.dart';

class ConnectTermsQuestion extends StatefulWidget {
  final QuestionItem questionItem;
  final Function(String) onAnswerSelected;

  const ConnectTermsQuestion({
    Key? key,
    required this.questionItem,
    required this.onAnswerSelected,
  }) : super(key: key);

  @override
  _ConnectTermsQuestionState createState() => _ConnectTermsQuestionState();
}

class _ConnectTermsQuestionState extends State<ConnectTermsQuestion> {
  List<String> _leftColumn = [];
  List<String> _rightColumn = [];

  @override
  void initState() {
    super.initState();
    _leftColumn = widget.questionItem.leftColumn ?? [];
    _rightColumn = widget.questionItem.rightColumn ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Connect the terms question - ${widget.questionItem.question}',
        ),
        SizedBox(
          height: 200,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (var term in _leftColumn)
                Draggable(
                  data: term,
                  feedback: Container(
                    width: 100,
                    height: 50,
                    color: Colors.green,
                    child: Center(
                      child: Text(term),
                    ),
                  ),
                  onDragEnd: (details) {
                    int index = _leftColumn.indexOf(term);
                    _leftColumn.remove(term);
                    _rightColumn.insert(index, term);
                    setState(() {});
                  },
                  child: Container(
                    width: 100,
                    height: 50,
                    color: Colors.blue,
                    child: Center(
                      child: Text(term),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (var term in _rightColumn)
                Draggable(
                  data: term,
                  feedback: Container(
                    width: 100,
                    height: 50,
                    color: Colors.green,
                    child: Center(
                      child: Text(term),
                    ),
                  ),
                  onDragEnd: (details) {
                    int index = _rightColumn.indexOf(term);
                    _rightColumn.remove(term);
                    _leftColumn.insert(index, term);
                    setState(() {});
                  },
                  child: Container(
                    width: 100,
                    height: 50,
                    color: Colors.red,
                    child: Center(
                      child: Text(term),
                    ),
                  ),
                ),
            ],
          ),
        ),
        TextButton(
          onPressed: () {
            String answer = _leftColumn.join(',');
            widget.onAnswerSelected(answer);
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
