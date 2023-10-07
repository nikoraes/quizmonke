from datetime import datetime
import json
import logging
import pathlib
from firebase_admin import storage, firestore
from firebase_functions import storage_fn
import google.cloud.firestore


def process_annotations(
    event: storage_fn.CloudEvent[storage_fn.StorageObjectData],
):
    firestore_client: google.cloud.firestore.Client = firestore.client()

    try:
        bucket_name = event.data.bucket
        file_path = pathlib.PurePath(event.data.name)

        print(str(file_path))

        if "annotations" not in str(file_path):
            return

        topic_id = str(file_path).split("/")[1]

        bucket = storage.bucket(bucket_name)
        blob = bucket.blob(str(file_path))
        annotation_responses = json.loads(blob.download_as_string())

        print(f"process_annotations - {topic_id} - {annotation_responses}")

        for res in annotation_responses["responses"]:
            # store in db
            firestore_client.collection(f"topics/{topic_id}/files").add(
                {
                    "uri": res["context"]["uri"],
                    "text": res["fullTextAnnotation"]["text"],
                }
            )

        firestore_client.collection("topics").document(topic_id).update(
            {"timestamp": firestore.SERVER_TIMESTAMP, "extractStatus": "done"}
        )

        return topic_id

    except Exception as error:
        error_name = type(error).__name__
        print(
            f"process_annotations - {topic_id} - Error while processing annotations: {error_name} {error} {error.__traceback__}"
        )
        firestore_client.collection("topics").document(topic_id).update(
            {"extractStatus": f"error: {error_name}"}
        )
        return None
