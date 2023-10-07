import logging
from typing import Any
from firebase_functions import https_fn
from firebase_admin import firestore
from google.cloud import vision
import google.cloud.firestore


def batch_annotate(req: https_fn.CallableRequest) -> Any:
    requests = []

    # TODO: note allowed to have more than 50 pages

    for uri in req.data["uris"]:
        source = {"image_uri": uri}
        image = {"source": source}
        features = [{"type_": vision.Feature.Type.DOCUMENT_TEXT_DETECTION}]
        requests.append({"image": image, "features": features})

    topic_id = req.data["topicId"]

    firestore_client: google.cloud.firestore.Client = firestore.client()

    try:
        output_uri = f"gs://schoolscan-4c8d8.appspot.com/topics/{topic_id}/annotations/"
        gcs_destination = {"uri": output_uri}
        batch_size = 50
        output_config = {"gcs_destination": gcs_destination, "batch_size": batch_size}

        vision_client = vision.ImageAnnotatorClient()

        print(f"{requests} - {output_config}")

        operation = vision_client.async_batch_annotate_images(
            requests=requests, output_config=output_config
        )

        print("batch_annotate - Waiting for operation to complete...")
        operation.result(60)

        return {"done": True}

    except Exception as error:
        error_name = type(error).__name__
        print(
            f"batch_annotate - Error while submitting annotation request: {error_name} {error} {error.__traceback__}"
        )
        firestore_client.collection("topics").document(topic_id).update(
            {"status": f"error: {error_name}"}
        )
        return {"done": False, "extractStatus": f"error: {error_name}"}
