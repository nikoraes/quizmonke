from firebase_admin import storage, firestore
import google.cloud.firestore


def delete_account_data(user_id: str):
    # Initialize Firestore client
    firestore_client: google.cloud.firestore.Client = firestore.client()
    # Initialize Storage bucket client
    bucket = storage.bucket()

    # Function to get all topics for a user
    def get_user_topics(user_id):
        topics = (
            firestore_client.collection("topics")
            .where(f"roles.{user_id}", "==", "owner")
            .stream()
        )
        return [topic.id for topic in topics]

    # Function to delete all data related to a topic
    def delete_topic_data(topic_id):
        batch = firestore_client.batch()

        # Delete questions
        questions = firestore_client.collection(f"topics/{topic_id}/questions").stream()
        for question in questions:
            batch.delete(question.reference)

        # Delete files
        files = firestore_client.collection(f"topics/{topic_id}/files").stream()
        for file in files:
            batch.delete(file.reference)

        # Delete topic
        topic_ref = firestore_client.collection("topics").document(topic_id)
        batch.delete(topic_ref)

        # Commit the batch
        batch.commit()

    def delete_topic_blobs(topic_id):
        blobs = bucket.list_blobs(prefix=f"topics/{topic_id}")
        for blob in blobs:
            blob.delete()

    # Get all topics for a user and delete data for each topic
    user_topics = get_user_topics(user_id)

    for topic_id in user_topics:
        delete_topic_data(topic_id)
        delete_topic_blobs(topic_id)

        # Get all files for this topic and delete them from storage
