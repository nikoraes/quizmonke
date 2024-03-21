import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

Future<void> generateTopicDetails(String topicId) async {
  try {
    // TODO: Set to generating immediately, because function cold start now makes this take a while
    // then try catch and do something
    final result = await FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable('generate_topic_details_fn')
        .call({"topicId": topicId});
    final response = result.data as Map<String, dynamic>;
    print("Response: $response");
    FirebaseAnalytics.instance
        .logEvent(name: "generate_topic_details", parameters: {
      "topic_id": topicId,
      "response": response,
    });
  } catch (err, stacktrace) {
    FirebaseCrashlytics.instance.recordError(err, stacktrace,
        reason: 'Error while generating topic details for $topicId');
    print("Error: $err");
  }
}
