import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MarkdownScreen extends StatelessWidget {
  const MarkdownScreen(
      {super.key, required this.title, this.subtitle, required this.markdown});

  final String title;
  final String? subtitle;
  final String markdown;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: Markdown(data: markdown));
  }
}
