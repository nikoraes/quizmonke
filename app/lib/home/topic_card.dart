import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:quizmonke/quiz/question_item.dart';
import 'package:quizmonke/quiz/quiz_screen.dart';
import 'package:quizmonke/utils/markdown_screen.dart';

Future<void> deleteTopic(String topicId) async {
  final batch = FirebaseFirestore.instance.batch();
  // questions
  var questions = await FirebaseFirestore.instance
      .collection("topics/$topicId/questions")
      .get();
  for (var doc in questions.docs) {
    batch.delete(doc.reference);
  }
  // files
  var files = await FirebaseFirestore.instance
      .collection("topics/$topicId/files")
      .get();
  for (var doc in files.docs) {
    batch.delete(doc.reference);
  }
  // topic
  var topicRef = FirebaseFirestore.instance.collection("topics").doc(topicId);
  batch.delete(topicRef);
  await batch.commit();
  FirebaseAnalytics.instance.logEvent(name: "delete_topic", parameters: {
    "topic_id": topicId,
  });
}

Future<void> generateQuiz(String topicId) async {
  // TODO: Set to generating immediately, because function cold start now makes this take a while
  // then try catch and do something
  final result = await FirebaseFunctions.instanceFor(region: 'europe-west1')
      .httpsCallable('generate_quiz_fn')
      .call({"topicId": topicId});
  final response = result.data as Map<String, dynamic>;
  print("Response: $response");
  FirebaseAnalytics.instance.logEvent(name: "generate_quiz", parameters: {
    "topic_id": topicId,
    "response": response,
  });
}

Future<void> generateSummary(String topicId) async {
  // TODO: Set to generating immediately, because function cold start now makes this take a while
  // then try catch and do something
  final result = await FirebaseFunctions.instanceFor(region: 'europe-west1')
      .httpsCallable('generate_summary_fn')
      .call({"topicId": topicId});
  final response = result.data as Map<String, dynamic>;
  print("Response: $response");
  FirebaseAnalytics.instance.logEvent(name: "generate_summary", parameters: {
    "topic_id": topicId,
    "response": response,
  });
}

Future<void> generateOutline(String topicId) async {
  // TODO: Set to generating immediately, because function cold start now makes this take a while
  // then try catch and do something
  final result = await FirebaseFunctions.instanceFor(region: 'europe-west1')
      .httpsCallable('generate_outline_fn')
      .call({"topicId": topicId});
  final response = result.data as Map<String, dynamic>;
  print("Response: $response");
  FirebaseAnalytics.instance.logEvent(name: "generate_outline", parameters: {
    "topic_id": topicId,
    "response": response,
  });
}

// TODO: create Firestore converters
class TopicCard extends StatefulWidget {
  final String id;
  final String? name;
  final String? description;
  final List<String>? tags;
  final String? status;
  final String? summary;
  final String? outline;
  final String? extractStatus;
  final String? quizStatus;
  final String? summaryStatus;
  final String? outlineStatus;

  const TopicCard({
    super.key,
    required this.id,
    this.name,
    this.description,
    this.tags,
    this.summary,
    this.outline,
    this.status,
    this.extractStatus,
    this.quizStatus,
    this.summaryStatus,
    this.outlineStatus,
  });

  factory TopicCard.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    String id = snapshot.id;
    return TopicCard(
      id: id,
      name: data?['name'],
      description: data?['description'],
      status: data?['status'],
      tags: data?['tags'] is Iterable ? List.from(data?['tags']) : null,
      extractStatus: data?['extractStatus'],
      quizStatus: data?['quizStatus'],
      summaryStatus: data?['summaryStatus'],
      summary: data?['summary'],
      outlineStatus: data?['outlineStatus'],
      outline: data?['outline'],
    );
  }

  @override
  _TopicCardState createState() => _TopicCardState();
}

class _TopicCardState extends State<TopicCard>
    with SingleTickerProviderStateMixin {
  bool isExpanded = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  void toggleExpansion() {
    setState(() {
      isExpanded = !isExpanded;
      if (isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    void openQuiz(String id) async {
      // Get all questions from store
      FirebaseFirestore.instance.collection("topics/$id/questions").get().then(
        (querySnapshot) {
          print("Successfully completed");
          for (var docSnapshot in querySnapshot.docs) {
            print('${docSnapshot.id} => ${docSnapshot.data()}');
          }
          List<QuestionItem> questions = <QuestionItem>[];
          for (var doc in querySnapshot.docs) {
            try {
              var q = QuestionItem.fromFirestore(doc, null);
              questions.add(q);
            } catch (e) {
              print("Error processing: $e");
            }
          }
          // Parse to QuestionItem
          /* List<QuestionItem> questions =
              querySnapshot.docs.map((querySnapshot) {
            return QuestionItem.fromFirestore(querySnapshot, null);
          }).toList(); */
          // Shuffle questions
          questions.shuffle();
          // Send to quiz (TODO: avoid using named route)
          Navigator.pushNamed(context, QuizScreen.routeName,
              arguments: QuizArguments(id, "${widget.name}", questions));
          FirebaseAnalytics.instance.logEvent(name: "open_quiz", parameters: {
            "topic_id": id,
            "questions_firebase_length": querySnapshot.docs.length,
            "questions_length": questions.length,
          });
        },
        onError: (e) => print("Error completing: $e"),
      );
    }

    void openSummary(String id, String summary) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MarkdownScreen(
            title: '${widget.name}',
            markdown: summary,
          ),
        ),
      );
      FirebaseAnalytics.instance.logEvent(name: "open_summary", parameters: {
        "topic_id": id,
      });
    }

    void openOutline(String id, String outline) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MarkdownScreen(
            title: '${widget.name}',
            markdown: outline,
          ),
        ),
      );
      FirebaseAnalytics.instance.logEvent(name: "open_outline", parameters: {
        "topic_id": id,
      });
    }

    void showDeleteDialog(BuildContext parentContext, String topicId) {
      showDialog(
        context: parentContext,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.deleteTopic),
            content: Text(AppLocalizations.of(context)!.areYouSure),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(parentContext);
                },
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () {
                  deleteTopic(topicId);
                  Navigator.pop(parentContext);
                },
                child: Text(AppLocalizations.of(context)!.delete),
              ),
            ],
          );
        },
      );
    }

    Widget buildMenu() {
      return MenuAnchor(
        builder:
            (BuildContext context, MenuController controller, Widget? child) {
          return IconButton(
            onPressed: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            icon: const Icon(Icons.more_vert),
          );
        },
        menuChildren: [
          MenuItemButton(
            child: Text(AppLocalizations.of(context)!.generateQuiz),
            onPressed: () {
              generateQuiz(widget.id);
            },
          ),
          MenuItemButton(
            child: Text(AppLocalizations.of(context)!.generateSummary),
            onPressed: () {
              generateSummary(widget.id);
            },
          ),
          MenuItemButton(
            child: Text(AppLocalizations.of(context)!.generateOutline),
            onPressed: () {
              generateOutline(widget.id);
            },
          ),
          MenuItemButton(
            child: Text(AppLocalizations.of(context)!.delete),
            onPressed: () {
              showDeleteDialog(context, widget.id);
            },
          ),
        ],
      );
    }

    Widget buildMainCard() {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                // Wrap the Text widget with Expanded
                child: Text(
                  widget.name ?? AppLocalizations.of(context)!.loading,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Menu
              buildMenu()
            ],
          ),
          const SizedBox(height: 4),
          if (widget.description != null)
            Align(
              alignment: Alignment.topLeft,
              child: Text('${widget.description}'),
            ),
          const SizedBox(height: 16),
        ],
      );
    }

    return Card(
      margin: const EdgeInsets.all(5.0),
      child: InkWell(
        customBorder: Theme.of(context).cardTheme.shape,
        onTap: () {
          toggleExpansion();
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 5, 5, 10),
          child: Column(
            children: [
              buildMainCard(),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                child: SizeTransition(
                  sizeFactor: _animationController
                      .drive(CurveTween(curve: Curves.easeInOut)),
                  child: Column(
                    children: [
                      // List of chips with tags
                      if (isExpanded && widget.tags != null)
                        Align(
                          alignment: Alignment.topLeft,
                          child: Wrap(
                            spacing:
                                4.0, // Adjust the spacing between chips as needed
                            runSpacing: -8.0,
                            children: widget.tags!
                                .map((tag) => Chip(
                                    label: Text(tag),
                                    padding: const EdgeInsets.all(0)))
                                .toList(),
                          ),
                        ),
                      if (isExpanded && widget.quizStatus != null)
                        ListTile(
                          dense: true,
                          visualDensity: const VisualDensity(vertical: -2),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 2.0, vertical: 0.0),
                          leading: widget.quizStatus == "done"
                              ? const Icon(Icons.quiz_outlined)
                              // TODO: show error icon if status is error
                              : const SizedBox(
                                  width: 20.0,
                                  height: 20.0,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.0, // Adjust the strokeWidth
                                  ),
                                ),
                          title: const Text('Quiz'),
                          onTap: () {
                            openQuiz(widget.id);
                          },
                        ),
                      if (isExpanded && widget.summaryStatus != null)
                        ListTile(
                          dense: true,
                          visualDensity: const VisualDensity(vertical: -2),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 2.0, vertical: 0.0),
                          leading: widget.summaryStatus == "done"
                              ? const Icon(Icons.text_snippet_outlined)
                              // TODO: show error icon if status is error
                              : const SizedBox(
                                  width: 20.0,
                                  height: 20.0,
                                  child: CircularProgressIndicator(),
                                ),
                          title: Row(
                            children: [
                              const Text('Summary '),
                              Badge(
                                alignment: Alignment.topLeft,
                                label: const Text('preview'),
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                textColor:
                                    Theme.of(context).colorScheme.onPrimary,
                              )
                            ],
                          ),
                          onTap: () {
                            if (widget.summary == null) return;
                            openSummary(widget.id, '${widget.summary}');
                          },
                        ),
                      if (isExpanded && widget.outlineStatus != null)
                        ListTile(
                          dense: true,
                          visualDensity: const VisualDensity(vertical: -2),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 2.0, vertical: 0.0),
                          leading: widget.outlineStatus == "done"
                              ? const Icon(Icons.format_list_bulleted_outlined)
                              // TODO: show error icon if status is error
                              : const SizedBox(
                                  width: 20.0,
                                  height: 20.0,
                                  child: CircularProgressIndicator(),
                                ),
                          title: Row(
                            children: [
                              const Text('Outline '),
                              Badge(
                                alignment: Alignment.topLeft,
                                label: const Text('preview'),
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                textColor:
                                    Theme.of(context).colorScheme.onPrimary,
                              )
                            ],
                          ),
                          onTap: () {
                            if (widget.outline == null) return;
                            openSummary(widget.id, '${widget.outline}');
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
