import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class PolicyScreen extends StatelessWidget {
  const PolicyScreen({
    super.key,
    required this.title,
    required this.mdFileName,
  });

  final String title;
  final String mdFileName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: FutureBuilder(
        future: Future.delayed(const Duration(milliseconds: 150)).then((value) {
          return rootBundle.loadString(mdFileName);
        }),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Markdown(
              data: '${snapshot.data}',
            );
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}
