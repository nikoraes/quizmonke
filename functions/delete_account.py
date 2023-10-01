from google.cloud import firestore


def delete_all_user_data(user_id: str):
    # Initialize Firestore client
    db = firestore.Client()

    # Function to get all topics for a user
    def get_user_topics(user_id):
        topics = (
            db.collection("topics").where(f"roles.{user_id}", "==", "owner").stream()
        )
        return [topic.id for topic in topics]

    # Function to delete all data related to a topic
    def delete_topic_data(topic_id):
        batch = db.batch()

        # Delete questions
        questions = db.collection(f"topics/{topic_id}/questions").stream()
        for question in questions:
            batch.delete(question.reference)

        # Delete files
        files = db.collection(f"topics/{topic_id}/files").stream()
        for file in files:
            batch.delete(file.reference)

        # Delete topic
        topic_ref = db.collection("topics").document(topic_id)
        batch.delete(topic_ref)

        # Commit the batch
        batch.commit()

    # Get all topics for a user and delete data for each topic
    user_topics = get_user_topics(user_id)

    for topic_id in user_topics:
        delete_topic_data(topic_id)
