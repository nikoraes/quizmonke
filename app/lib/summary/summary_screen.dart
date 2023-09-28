import 'package:flutter/material.dart';

class SummaryArguments {
  final String topicId;
  final String summary;

  SummaryArguments(this.topicId, this.summary);
}

class SummaryScreen extends StatefulWidget {
  static String routeName = '/summary';
  const SummaryScreen({super.key});

  @override
  _SummaryScreenState createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  late String summary;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as SummaryArguments;
    summary = args.summary;

    return Scaffold(
        appBar: AppBar(
          title: Text('Summary ${args.topicId}'),
        ),
        body: Text(summary));
  }
}
