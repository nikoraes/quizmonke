import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quizmonke/photo_screen.dart';
import 'package:quizmonke/quiz_screen.dart';

class MyHomePage extends StatefulWidget {
  static String routeName = '/';
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void _addTopic() {
    print("Add topic");

    // Multi-image camera
    // https://pub.dev/packages/multiple_image_camera/example
    Navigator.pushNamed(context, PhotoScreen.routeName);

    // upload multiple files
    // https://stackoverflow.com/questions/63513002/how-can-i-upload-multiple-images-to-firebase-in-flutter-and-get-all-their-downlo
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        title: const Text('QuizMonke'),
      ),
      body: const TopicsList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTopic,
        label: const Text('New topic'),
        icon: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class TopicsList extends StatefulWidget {
  const TopicsList({super.key});

  @override
  TopicsListState createState() => TopicsListState();
}

class TopicsListState extends State<TopicsList> {
  final Stream<QuerySnapshot> _topicsStream = FirebaseFirestore.instance
      .collection('topics')
      .where('roles.${FirebaseAuth.instance.currentUser?.uid}',
          whereIn: ["reader", "owner"]).snapshots();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _topicsStream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return const Text('Something went wrong');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text("Loading");
        }

        return ListView(
          children: snapshot.data!.docs
              .map((DocumentSnapshot document) {
                Map<String, dynamic> data =
                    document.data()! as Map<String, dynamic>;
                String id = document.id;
                return TopicCard(
                  id: id,
                  name: data['name'],
                );
              })
              .toList()
              .cast(),
        );
      },
    );
  }
}

class TopicCard extends StatelessWidget {
  final String id;
  final String? name;

  const TopicCard({super.key, required this.id, this.name});

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
              .toList();
          Navigator.pushNamed(context, QuizScreen.routeName,
              arguments: QuizArguments(id, questions));
        },
        onError: (e) => print("Error completing: $e"),
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
                        IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {},
                        ),
                      ],
                    ))
                  ],
                ),
                const SizedBox(height: 20),
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
