import json
import os
import pathlib
from typing import Any

from firebase_functions import https_fn
from firebase_admin import initialize_app, storage
from firebase_functions import firestore_fn, https_fn, storage_fn
import google.cloud.firestore
from google.cloud import vision
from langchain import PromptTemplate

from langchain.llms import OpenAI

llm = OpenAI(openai_api_key=os.environ.get("OPENAI_API_KEY"))


initialize_app()


@https_fn.on_call()
def batchannotate(req: https_fn.CallableRequest) -> Any:
    print(
        "batchannotate auth=%s, data=%s",
        req.auth,
        req.data,
    )

    requests = []

    # TODO: note allowed to have more than 50 pages

    for uri in req.data["uris"]:
        source = {"image_uri": uri}
        image = {"source": source}
        features = [{"type_": vision.Feature.Type.DOCUMENT_TEXT_DETECTION}]
        requests.append({"image": image, "features": features})

    topicId = req.data["topicId"]

    output_uri = f"gs://schoolscan-4c8d8.appspot.com/topics/{topicId}/annotations/"
    gcs_destination = {"uri": output_uri}
    batch_size = 50
    output_config = {"gcs_destination": gcs_destination, "batch_size": batch_size}

    vision_client = vision.ImageAnnotatorClient()

    print(requests, output_config)

    operation = vision_client.async_batch_annotate_images(
        requests=requests, output_config=output_config
    )

    print("Waiting for operation to complete...")
    response = operation.result(90)
    print(response)
    return {"done": True}


@storage_fn.on_object_finalized(region="europe-west1")
def generate_quiz(
    event: storage_fn.CloudEvent[storage_fn.StorageObjectData],
):
    bucket_name = event.data.bucket
    file_path = pathlib.PurePath(event.data.name)

    print(str(file_path), event.data.name)

    if "annotations" not in str(file_path):
        return

    bucket = storage.bucket(bucket_name)
    blob = bucket.blob(str(file_path))
    annotation_responses = json.loads(blob.download_as_string())

    print(annotation_responses)

    fulltext = ""

    for res in annotation_responses["responses"]:
        print(res["context"]["uri"])
        print(res["fullTextAnnotation"])
        print(res["fullTextAnnotation"]["text"])
        # add to total text
        fulltext += "\n" + res["fullTextAnnotation"]["text"]

    print("{fulltext}")

    template = """You are a helpful assistant who generates json output. 
You will receive a piece of text and you will need to create a quiz based on that text. 
The quiz will have 5 questions and you can have 3 types of questions: 
1.Multiple choice: provide at least 3 choices per question. The correct answer can be A, B, C, D ...
2.Connect relevant terms: 3 terms in a random order in 1 column and 3 terms in a random order in the other column. The person that takes the test must connect the terms between the columns. An answer can be A2,B1,C3 for instance.
3.A free text question where the answer should be a single word.
For each question, you also need to provide the answer.
Questions, choices, answers should be in the same language as the provided text.
Input text: {text}"""
    prompt = PromptTemplate.from_template(template)
    prompt.format(text=fulltext)

    print(llm(prompt))
