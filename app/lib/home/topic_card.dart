import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quizmonke/quiz/question_item.dart';
import 'package:quizmonke/quiz/quiz_screen.dart';

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

class TopicCard extends StatelessWidget {
  final String id;
  final String? name;
  final String? status;

  const TopicCard({super.key, required this.id, this.name, this.status});

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
          List<QuestionItem> questions = querySnapshot.docs
              .map((querySnapshot) {
                return QuestionItem.fromFirestore(querySnapshot, null);
              })
              .cast<QuestionItem>()
              .where(
                (element) => element.type == 'multiple_choice',
              )
              .toList();
          Navigator.pushNamed(context, QuizScreen.routeName,
              arguments: QuizArguments(id, questions));
        },
        onError: (e) => print("Error completing: $e"),
      );
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
                const SizedBox(height: 20),
                if (status != null)
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Text('$status'),
                  ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(id),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
