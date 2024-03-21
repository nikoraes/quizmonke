import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

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
