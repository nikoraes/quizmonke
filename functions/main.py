import json
import os
import pathlib
from typing import Any

from firebase_functions import https_fn, options
from firebase_admin import initialize_app, storage, firestore
from firebase_functions import firestore_fn, https_fn, storage_fn
import google.cloud.firestore
from google.cloud import vision

from langchain.chains.openai_functions import (
    create_openai_fn_chain,
    create_structured_output_chain,
)
from langchain import PromptTemplate
from langchain.prompts import ChatPromptTemplate
from langchain.chat_models import ChatOpenAI
from langchain.llms import OpenAI


initialize_app()


@https_fn.on_call(memory=options.MemoryOption.MB_512)
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
    operation.result(90)
    return {"done": True}


@storage_fn.on_object_finalized(
    region="europe-west1", memory=options.MemoryOption.MB_512
)
def generate_quiz(
    event: storage_fn.CloudEvent[storage_fn.StorageObjectData],
):
    bucket_name = event.data.bucket
    file_path = pathlib.PurePath(event.data.name)

    print(str(file_path), event.data.name)

    if "annotations" not in str(file_path):
        return

    topic_id = str(file_path).split("/")[1]

    firestore_client: google.cloud.firestore.Client = firestore.client()
    firestore_client.collection("topics").document(topic_id).update(
        {"status": "generating"}
    )

    bucket = storage.bucket(bucket_name)
    blob = bucket.blob(str(file_path))
    annotation_responses = json.loads(blob.download_as_string())

    print(annotation_responses)

    fulltext = ""

    for res in annotation_responses["responses"]:
        # add to total text
        fulltext += "\n" + res["fullTextAnnotation"]["text"]

    # TODO: use pydantic or covert to true json schema
    json_schema = {
        "$schema": "http://json-schema.org/draft-07/schema#",
        "type": "object",
        "properties": {
            "name": {"type": "string", "minLength": 1},
            "description": {"type": "string"},
            "language": {"type": "string"},
            "questions": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "type": {
                            "type": "string",
                            "enum": ["free_text", "multiple_choice", "connect_terms"],
                        },
                        "question": {"type": "string"},
                        "choices": {
                            "type": "array",
                            "items": {"type": "string"},
                            "minItems": 2,
                        },
                        "left_column": {
                            "type": "array",
                            "items": {"type": "string"},
                            "minItems": 2,
                        },
                        "right_column": {
                            "type": "array",
                            "items": {"type": "string"},
                            "minItems": 2,
                        },
                        "answer": {
                            "type": "object",
                            "additionalProperties": {"type": "string"},
                        },
                    },
                    "required": ["type", "question"],
                },
            },
        },
        "required": ["name", "questions"],
    }

    prompt = ChatPromptTemplate.from_messages(
        [
            (
                "system",
                "You are a world class algorithm for generating quizzes in structured formats.",
            ),
            (
                "human",
                """You will receive a piece of text and you will need to create a quiz based on that text (in the same language). You will also detect the language of the text and provide a quiz title and short description.
The quiz will have 10 questions and you can have 3 types of questions: 
1.Multiple choice: provide at least 3 choices per question. The correct answer can be A, B, C, D ... 
2.Connect relevant terms: 3 terms in a random order in 1 column and 3 terms in a random order in the other column. The person that takes the test must connect the terms between the columns. An answer can be A2,B1,C3 for instance.
3.A free text question where the answer should be a single word.
For each question, you also need to provide the correct answer. Make sure that the correct answer is exactly the same as the value of the choice.
You also need to detect the language of the text. The values of the name, description, questions, choices, answers should be in the same language as the provided text.
Input: {input}""",
            ),
            (
                "human",
                "Tip: Make sure to answer in the correct format and in the correct language (only the values).",
            ),
        ]
    )

    print(os.environ.get("OPENAI_API_KEY"))
    llm = ChatOpenAI(openai_api_key=os.environ.get("OPENAI_API_KEY"))
    chain = create_structured_output_chain(json_schema, llm, prompt, verbose=True)
    res = chain.run(fulltext)

    # prompt = PromptTemplate.from_template(template)
    # prompt_text = prompt.format(text=fulltext)
    # print(prompt_text)

    # res = llm(prompt_text)

    print(res)

    firestore_client.collection("topics").document(topic_id).update(
        {
            "status": "Done1",
            "name": res["name"],
            "language": res["language"],
            "description": res["description"],
        }
    )

    for question in res["questions"]:
        firestore_client.collection(f"topics/{topic_id}/questions").add(question)

    firestore_client.collection("topics").document(topic_id).update(
        {
            "status": "done",
            "name": res["name"],
            "language": res["language"],
            "description": res["description"],
        }
    )
    print("done")
