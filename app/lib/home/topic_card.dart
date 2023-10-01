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
  final result = await FirebaseFunctions.instanceFor(region: 'europe-west1')
      .httpsCallable('generate_quiz_fn')
      .call({"topicId": topicId});
  final response = result.data as Map<String, dynamic>;
  print("Response: $response");
}

Future<void> generateSummary(String topicId) async {
  final result = await FirebaseFunctions.instanceFor(region: 'europe-west1')
      .httpsCallable('summarize_fn')
      .call({"topicId": topicId});
  final response = result.data as Map<String, dynamic>;
  print("Response: $response");
}

// TODO: https://stackoverflow.com/questions/56273062/flutter-collapsible-expansible-card

class TopicCard extends StatelessWidget {
  final String id;
  final String? name;
  final String? description;
  final String? status;
  final String? summary;
  final String? extractStatus;
  final String? quizStatus;
  final String? summaryStatus;

  const TopicCard(
      {super.key,
      required this.id,
      this.name,
      this.description,
      this.summary,
      this.status,
      this.extractStatus,
      this.quizStatus,
      this.summaryStatus});

  @override
  Widget build(BuildContext context) {
    void openQuiz(String id) async {
      print("Card $id Clicked");
      FirebaseFirestore.instance.collection("topics/$id/questions").get().then(
        (querySnapshot) {
          print("Successfully completed");
          for (var docSnapshot in querySnapshot.docs) {
            print('${docSnapshot.id} => ${docSnapshot.data()}');
          }
          List<QuestionItem> questions =
              querySnapshot.docs.map((querySnapshot) {
            return QuestionItem.fromFirestore(querySnapshot, null);
          }).toList();
          Navigator.pushNamed(context, QuizScreen.routeName,
              arguments: QuizArguments(id, "$name", questions));
        },
        onError: (e) => print("Error completing: $e"),
      );
    }

    void openSummary(String id, String summary) {
      Navigator.pushNamed(context, SummaryScreen.routeName,
          arguments: SummaryArguments(id, "$name", summary));
    }

    void showDeleteDialog(BuildContext parentContext, String topicId) {
      showDialog(
        context: parentContext,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Delete quiz!'),
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

    return Padding(
      padding: const EdgeInsets.all(5),
      child: Card(
        child: InkWell(
          onTap: () {
            openQuiz(id);
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 5, 5, 10),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    if (name != null)
                      Text('$name',
                          style: Theme.of(context).textTheme.titleMedium),
                    Expanded(
                        child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        MenuAnchor(
                          builder: (BuildContext context,
                              MenuController controller, Widget? child) {
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
                                generateQuiz(id);
                              },
                            ),
                            MenuItemButton(
                              child: const Text('Generate Summary'),
                              onPressed: () {
                                generateSummary(id);
                              },
                            ),
                            MenuItemButton(
                              child: const Text('Delete'),
                              onPressed: () {
                                showDeleteDialog(context, id);
                              },
                            ),
                          ],
                        ),
                      ],
                    ))
                  ],
                ),
                if (description != null)
                  Align(
                    alignment: Alignment.topLeft,
                    child: Text('$description'),
                  ),
                /* Align(
                  alignment: Alignment.topLeft,
                  child: Text(id),
                ), */
                const SizedBox(height: 20),
                if (status != null)
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
                  ),
                if (summary != null)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.text_snippet_outlined),
                    title: const Text('Summary'),
                    onTap: () {
                      openSummary(id, '$summary');
                    },
                  ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.question_mark_outlined),
                  title: const Text('Quiz'),
                  onTap: () {
                    openQuiz(id);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
