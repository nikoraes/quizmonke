import json
import pathlib
from typing import Any, List, Optional
from firebase_functions import https_fn, options
from firebase_admin import initialize_app, storage, firestore
from firebase_functions import https_fn, storage_fn
import google.cloud.firestore
from google.cloud import vision
import vertexai
from langchain.prompts import PromptTemplate
from langchain.llms import VertexAI
from langchain.output_parsers import PydanticOutputParser
from langchain.pydantic_v1 import BaseModel, Field
from langchain.chains.summarize import load_summarize_chain
from langchain.text_splitter import RecursiveCharacterTextSplitter


def batch_annotate(req: https_fn.CallableRequest) -> Any:
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

    topic_id = req.data["topicId"]

    output_uri = f"gs://schoolscan-4c8d8.appspot.com/topics/{topic_id}/annotations/"
    gcs_destination = {"uri": output_uri}
    batch_size = 50
    output_config = {"gcs_destination": gcs_destination, "batch_size": batch_size}

    vision_client = vision.ImageAnnotatorClient()

    print(requests, output_config)

    operation = vision_client.async_batch_annotate_images(
        requests=requests, output_config=output_config
    )

    print("Waiting for operation to complete...")
    operation.result(60)

    return {"done": True}
