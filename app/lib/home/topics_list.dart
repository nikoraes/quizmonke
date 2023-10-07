import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:quizmonke/home/topic_card.dart';

class TopicsList extends StatefulWidget {
  const TopicsList({super.key});

  @override
  TopicsListState createState() => TopicsListState();
}

class TopicsListState extends State<TopicsList> {
  late Stream<QuerySnapshot> _topicsStream;

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  void _initializeStream() {
    _topicsStream = FirebaseFirestore.instance.collection('topics').where(
            'roles.${FirebaseAuth.instance.currentUser?.uid}',
            whereIn: ["reader", "owner"])
        // .orderBy("timestamp", descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _topicsStream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              AppLocalizations.of(context)!.oops,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context)!.welcomeText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.noTopicsText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView(
          children: snapshot.data!.docs
              .map((DocumentSnapshot snapshot) {
                return TopicCard.fromFirestore(
                    snapshot as DocumentSnapshot<Map<String, dynamic>>, null);
              })
              .toList()
              .cast<TopicCard>()
            ..sort((a, b) {
              // Get timestamps if available
              Timestamp? timestampA = a.timestamp;
              Timestamp? timestampB = b.timestamp;

              // Handle cases where timestamps are null or missing
              if (timestampA == null && timestampB == null) {
                return 0; // No preference when both are missing
              } else if (timestampA == null) {
                return 1; // Move items with missing timestamp to the end
              } else if (timestampB == null) {
                return -1; // Move items with missing timestamp to the end
              } else {
                // Compare timestamps in descending order
                return timestampB.seconds.compareTo(timestampA.seconds);
              }
            }),
        );
      },
    );
  }
}
