import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:quizmonke/ad_helper.dart';
import 'package:quizmonke/quiz/question_connect_terms.dart';
import 'package:quizmonke/quiz/question_free_text.dart';
import 'package:quizmonke/quiz/question_item.dart';
import 'package:quizmonke/quiz/question_multiple_choice.dart';
import 'package:quizmonke/quiz/question_multiple_choice_multi.dart';

enum QuestionResult { correct, wrong, skipped }

class QuizScreen extends StatefulWidget {
  final String topicId;
  final String topicName;
  final List<QuestionItem> questions;

  const QuizScreen(
      {super.key,
      required this.topicId,
      required this.topicName,
      required this.questions});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<QuestionItem> questions;
  int currentIndex = 0;

  int numberCorrect = 0;
  int numberWrong = 0;
  int numberSkipped = 0;

  InterstitialAd? _interstitialAd;

  @override
  void initState() {
    super.initState();
    setState(() {
      questions = widget.questions;
    });
    _loadInterstitialAd();
  }

  void _moveToHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _nextQuestion() {
    setState(() {
      currentIndex++; // Move to the next question
    });

    /* if ((currentIndex == 0 || currentIndex % 5 != 0) && (_interstitialAd != null)) {
      _interstitialAd?.show();
    }  */
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          setState(() {
            _interstitialAd = ad;
          });
        },
        onAdFailedToLoad: (err) async {
          await FirebaseCrashlytics.instance
              .log('Failed to load an interstitial ad: ${err.message}');
          print('Failed to load an interstitial ad: ${err.message}');
        },
      ),
    );
  }

  void showCongratulatoryScreen(BuildContext parentContext) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.congratulations),
          content: Text(AppLocalizations.of(context)!.answerCorrect),
          actions: [
            TextButton(
              onPressed: () {
                print('currentIndex: $currentIndex / ${questions.length}');
                // Move to the next question if there are more questions
                _nextQuestion();
                Navigator.pop(parentContext);
              },
              child: Text(AppLocalizations.of(context)!.nextQuestion),
            ),
          ],
        );
      },
    );
  }

  void showIncorrectAnswerScreen(
      BuildContext parentContext, QuestionItem questionItem) {
    // Show dialog
    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.bluh),
          content: Text(AppLocalizations.of(context)!
              .answerWrong('${questionItem.answer?.replaceAll(',', '\n')}')),
          actions: [
            /* TextButton(
              onPressed: () {
                Navigator.pop(parentContext);
              },
              child: Text(AppLocalizations.of(context)!.tryAgain),
            ), */
            TextButton(
              onPressed: () {
                print('currentIndex: $currentIndex / ${questions.length}');
                // Move to the next question if there are more questions
                _nextQuestion();
                // Add the question to the end again
                questions.add(questionItem);
                // close dialog
                Navigator.pop(parentContext);
              },
              child: Text(AppLocalizations.of(context)!.nextQuestion),
            ),
            // TODO: also add a skip button here and ask why it was skipped
          ],
        );
      },
    );
  }

  void showSkippedAnswerScreen(
      BuildContext parentContext, QuestionItem questionItem) {
    // Variables to track selected issue and whether the 'Delete' button is enabled
    String selectedIssue = '';
    bool isDeleteButtonEnabled = false;

    // Show dialog
    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.skipped),
            // Add something to provide feedback on why it was skipped (and potentially remove the question from the quiz)
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppLocalizations.of(context)!.answerSkipped(
                    '${questionItem.answer?.replaceAll(',', '\n')}')),
                const SizedBox(height: 16),
                // List of radio buttons for potential issues
                for (String issue in [
                  AppLocalizations.of(context)!.questionTooHard,
                  AppLocalizations.of(context)!.questionTooSimple,
                  AppLocalizations.of(context)!.incorrectCorrectAnswer,
                  AppLocalizations.of(context)!.other
                ])
                  RadioListTile(
                    title: Text(issue),
                    value: issue,
                    groupValue: selectedIssue,
                    dense: true,
                    onChanged: (value) {
                      setState(() {
                        selectedIssue = value.toString();
                        isDeleteButtonEnabled = true;
                      });
                    },
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isDeleteButtonEnabled
                    ? () {
                        if (isDeleteButtonEnabled) {
                          FirebaseAnalytics.instance.logEvent(
                              name: "quiz_answer_deleted",
                              parameters: {
                                "topic_id": widget.topicId,
                                "question_id": questionItem.id,
                                "reason": selectedIssue,
                                "result": QuestionResult.correct.name,
                              });
                          FirebaseFirestore.instance
                              .collection("topics/${widget.topicId}/questions")
                              .doc(questionItem.id)
                              .update({
                            'isDeleted': true,
                            'deletedReason': selectedIssue
                          });
                          // TODO:  Add logic to delete the question and move to the next question
                          print('Delete question with issue: $selectedIssue');
                          _nextQuestion();
                          Navigator.pop(parentContext);
                        }
                      }
                    : null,
                child: Text(
                  AppLocalizations.of(context)!.delete,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  FirebaseAnalytics.instance
                      .logEvent(name: "quiz_answer_skipped", parameters: {
                    "topic_id": widget.topicId,
                    "question_id": questionItem.id,
                    "reason": selectedIssue,
                    "result": QuestionResult.correct.name,
                  });
                  // Move to the next question if there are more questions
                  _nextQuestion();
                  Navigator.pop(parentContext);
                },
                child: Text(AppLocalizations.of(context)!.nextQuestion),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    /* final args = ModalRoute.of(context)!.settings.arguments as QuizArguments;
    questions = args.questions;
    topicId = args.topicId; */

    void onAnswerChecked(QuestionItem questionItem, QuestionResult result) {
      FirebaseAnalytics.instance
          .logEvent(name: "quiz_answer_checked", parameters: {
        "topic_id": widget.topicId,
        "question_id": questionItem.id,
        "result": QuestionResult.correct.name,
      });
      if (result == QuestionResult.correct) {
        showCongratulatoryScreen(context);
        setState(() {
          numberCorrect++;
        });
      } else if (result == QuestionResult.skipped) {
        showSkippedAnswerScreen(context, questionItem);
        setState(() {
          numberSkipped++;
        });
      } else {
        showIncorrectAnswerScreen(context, questionItem);
        setState(() {
          numberWrong++;
        });
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.topicName} - $currentIndex/${questions.length}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: (currentIndex < questions.length &&
                (currentIndex == 0 || currentIndex % 5 != 0))
            ? _buildQuestion(context, ValueKey(questions[currentIndex]),
                widget.topicId, questions[currentIndex], (correct) {
                onAnswerChecked(questions[currentIndex], correct);
              })
            : Align(
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 100),
                    Text(
                      AppLocalizations.of(context)!.quizCompleted,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      AppLocalizations.of(context)!.resultsOverview,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                        '${AppLocalizations.of(context)!.correctLabel} $numberCorrect'),
                    Text(
                        '${AppLocalizations.of(context)!.wrongLabel} $numberWrong'),
                    Text(
                        '${AppLocalizations.of(context)!.skippedLabel} $numberSkipped'),
                    const SizedBox(height: 20),
                    // Only show this button if there are more than 5 additional questions available
                    if (questions.length - (currentIndex + 1) > 5)
                      ElevatedButton(
                        onPressed: () async {
                          if (!kIsWeb && _interstitialAd != null) {
                            await _interstitialAd?.show();
                            if (_interstitialAd != null) {
                              _interstitialAd!.dispose();
                            }
                            _interstitialAd = null;
                            // Load new ad in background
                            _loadInterstitialAd();
                          }
                          _nextQuestion();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                        ),
                        child:
                            Text(AppLocalizations.of(context)!.moreQuestions),
                      ),
                    // TODO: allow to generate more
                    /* ElevatedButton(
                      onPressed: questions.length - () {
                        generateQuiz(topicId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                      child: Text(AppLocalizations.of(context)!.generateMore),
                    ), */
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () async {
                        if (!kIsWeb && kDebugMode && _interstitialAd != null) {
                          await _interstitialAd?.show();
                          if (_interstitialAd != null) {
                            _interstitialAd!.dispose();
                          }
                          _interstitialAd = null;
                        }
                        _moveToHome();
                      },
                      child: Text(AppLocalizations.of(context)!.back),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    // Dispose the InterstitialAd object
    if (_interstitialAd != null) _interstitialAd?.dispose();

    super.dispose();
  }
}

Widget _buildQuestion(BuildContext context, Key key, String topicId,
    QuestionItem questionItem, Function(QuestionResult) onAnswerChecked) {
  FirebaseAnalytics.instance.logEvent(name: "quiz_build_question", parameters: {
    "topic_id": topicId,
    "question_id": questionItem.id,
    "type": questionItem.type,
  });
  if (questionItem.type == "multiple_choice") {
    return QuestionMultipleChoice(
        key: key, questionItem: questionItem, onAnswerChecked: onAnswerChecked);
  } else if (questionItem.type == "multiple_choice_multi") {
    return QuestionMultipleChoiceMulti(
        key: key, questionItem: questionItem, onAnswerChecked: onAnswerChecked);
  } else if (questionItem.type == "connect_terms") {
    return QuestionConnectTerms(
        key: key, questionItem: questionItem, onAnswerChecked: onAnswerChecked);
  } else if (questionItem.type == "free_text") {
    return QuestionFreeText(
        key: key,
        topicId: topicId,
        questionItem: questionItem,
        onAnswerChecked: onAnswerChecked);
  } else {
    return InkWell(
      onTap: () {
        onAnswerChecked(QuestionResult.skipped);
      },
      child: Text(
          AppLocalizations.of(context)!.unsupportedQuestion(questionItem.type)),
    );
  }
}
