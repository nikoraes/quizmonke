import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quizmonke/home/topic_card.dart';

class TopicsList extends StatefulWidget {
  const TopicsList({super.key});

  @override
  TopicsListState createState() => TopicsListState();
}

class TopicsListState extends State<TopicsList> {
  final Stream<QuerySnapshot> _topicsStream = FirebaseFirestore.instance
      .collection('topics')
      .where('roles.${FirebaseAuth.instance.currentUser?.uid}',
          whereIn: ["reader", "owner"])
      .orderBy(FieldPath.documentId, descending: true)
      .snapshots();

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
                  description: data['description'],
                  status: data['status'],
                  extractStatus: data['extractStatus'],
                  quizStatus: data['quizStatus'],
                  summaryStatus: data['summaryStatus'],
                  summary: data['summary'],
                );
              })
              .toList()
              .cast(),
        );
      },
    );
  }
}
