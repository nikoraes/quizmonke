import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:quizmonke/quiz/question_item.dart';
import 'package:quizmonke/quiz/quiz_screen.dart';
import 'package:quizmonke/summary/summary_screen.dart';

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
}

Future<void> generateQuiz(String topicId) async {
  // TODO: Set to generating immediately, because function cold start now makes this take a while
  // then try catch and do something
  final result = await FirebaseFunctions.instanceFor(region: 'europe-west1')
      .httpsCallable('generate_quiz_fn')
      .call({"topicId": topicId});
  final response = result.data as Map<String, dynamic>;
  print("Response: $response");
}

Future<void> generateSummary(String topicId) async {
  // TODO: Set to generating immediately, because function cold start now makes this take a while
  // then try catch and do something
  final result = await FirebaseFunctions.instanceFor(region: 'europe-west1')
      .httpsCallable('generate_summary_fn')
      .call({"topicId": topicId});
  final response = result.data as Map<String, dynamic>;
  print("Response: $response");
}

Future<void> generateOutline(String topicId) async {
  // TODO: Set to generating immediately, because function cold start now makes this take a while
  // then try catch and do something
  final result = await FirebaseFunctions.instanceFor(region: 'europe-west1')
      .httpsCallable('generate_outline_fn')
      .call({"topicId": topicId});
  final response = result.data as Map<String, dynamic>;
  print("Response: $response");
}

class TopicCard extends StatefulWidget {
  final String id;
  final String? name;
  final String? description;
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
    this.summary,
    this.outline,
    this.status,
    this.extractStatus,
    this.quizStatus,
    this.summaryStatus,
    this.outlineStatus,
  });
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
      print("Card $id Clicked");
      // Get all questions from store
      FirebaseFirestore.instance.collection("topics/$id/questions").get().then(
        (querySnapshot) {
          print("Successfully completed");
          for (var docSnapshot in querySnapshot.docs) {
            print('${docSnapshot.id} => ${docSnapshot.data()}');
          }
          // Parse to QuestionItem
          List<QuestionItem> questions =
              querySnapshot.docs.map((querySnapshot) {
            return QuestionItem.fromFirestore(querySnapshot, null);
          }).toList();
          // Shuffle questions
          questions.shuffle();
          // Send to quiz (TODO: avoid using named route)
          Navigator.pushNamed(context, QuizScreen.routeName,
              arguments: QuizArguments(id, "${widget.name}", questions));
        },
        onError: (e) => print("Error completing: $e"),
      );
    }

    void openSummary(String id, String summary) {
      Navigator.pushNamed(context, SummaryScreen.routeName,
          arguments: SummaryArguments(id, "${widget.name}", summary));
    }

    void showDeleteDialog(BuildContext parentContext, String topicId) {
      showDialog(
        context: parentContext,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Delete topic!'),
            content: const Text('Are you sure?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(parentContext);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  deleteTopic(topicId);
                  Navigator.pop(parentContext);
                },
                child: const Text('Delete'),
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
            tooltip: 'Show menu',
          );
        },
        menuChildren: [
          MenuItemButton(
            child: const Text('Generate Quiz'),
            onPressed: () {
              generateQuiz(widget.id);
            },
          ),
          MenuItemButton(
            child: const Text('Generate Summary'),
            onPressed: () {
              generateSummary(widget.id);
            },
          ),
          MenuItemButton(
            child: const Text('Generate Summary'),
            onPressed: () {
              generateOutline(widget.id);
            },
          ),
          MenuItemButton(
            child: const Text('Delete'),
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
              // TODO: progress indicator should have more padding
              if (widget.quizStatus != "done")
                const SizedBox(
                  width: 20.0,
                  height: 20.0,
                  child: CircularProgressIndicator(),
                ),
              if (widget.name != null)
                Expanded(
                  // Wrap the Text widget with Expanded
                  child: Text(
                    '${widget.name}',
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                Expanded(
                  // Wrap the Text widget with Expanded
                  child: Text(
                    "Loading",
                    style: Theme.of(context).textTheme.titleSmall,
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
          /* Align(
                  alignment: Alignment.topLeft,
                  child: Text(id),
                ), */
          const SizedBox(height: 20),
          /* if (status != null)
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Text('status: $status'),
                  ),
                if (extractStatus != null)
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Text('extraction: $extractStatus'),
                  ),
                if (summaryStatus != null)
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Text('summary: $summaryStatus'),
                  ),
                if (quizStatus != null)
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Text('quiz: $quizStatus'),
                  ), */
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
                      if (isExpanded)
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
                      if (isExpanded)
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
                            openSummary(widget.id, '${widget.summary}');
                          },
                        ),
                      if (isExpanded)
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
                              const Text('Outline'),
                              Badge(
                                alignment: Alignment.topLeft,
                                label: const Text('coming soon'),
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                textColor:
                                    Theme.of(context).colorScheme.onPrimary,
                              )
                            ],
                          ),
                          onTap: () {
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
