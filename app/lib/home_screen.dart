import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Home'),
      ),
      body:
          const TopicsList(), // This trailing comma makes auto-formatting nicer for build methods.
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
                return ListTile(
                  title: Text(data['name']),
                );
              })
              .toList()
              .cast(),
        );
      },
    );
  }
}
