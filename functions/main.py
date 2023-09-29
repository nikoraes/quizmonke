import json
import pathlib
import logging
from typing import Any, List, Optional
from firebase_functions import https_fn, options
from firebase_admin import initialize_app, storage, firestore
from firebase_functions import https_fn, storage_fn
import google.cloud.firestore
from google.cloud import vision
import vertexai
import google.cloud.logging

from langchain.prompts import PromptTemplate
from langchain.llms import VertexAI
from langchain.output_parsers import PydanticOutputParser
from langchain.pydantic_v1 import BaseModel, Field
from langchain.chains.summarize import load_summarize_chain
from langchain.text_splitter import RecursiveCharacterTextSplitter

from batch_annotate import batch_annotate
from process_annotations import process_annotations
from generate_quiz import generate_quiz
from summarize import summarize


initialize_app()

logging_client = google.cloud.logging.Client()
logging_client.setup_logging()


@https_fn.on_call(region="europe-west1", memory=options.MemoryOption.MB_512)
def batch_annotate_fn(req: https_fn.CallableRequest) -> Any:
    logging.info(f"batch_annotate_fn: {req.data}")
    return batch_annotate(req)


@storage_fn.on_object_finalized(
    region="europe-west1", memory=options.MemoryOption.MB_512
)
def process_annotations_fn(
    event: storage_fn.CloudEvent[storage_fn.StorageObjectData],
):
    topic_id = process_annotations(event)
    if topic_id == None:
        return
    logging.info(f"process_annotations_fn - Annotations processed: {topic_id}")
    quiz_res = generate_quiz(topic_id)
    if quiz_res["done"]:
        logging.info(f"process_annotations_fn - Quiz generated: {topic_id}")
    else:
        logging.error(f"process_annotations_fn - Quiz generation failed: {topic_id}")

    summ_res = summarize(topic_id)
    if summ_res["done"]:
        logging.info(f"process_annotations_fn - Summary generated: {topic_id}")
    else:
        logging.error(f"process_annotations_fn - Summary generation failed: {topic_id}")


@https_fn.on_call(region="europe-west1", memory=options.MemoryOption.MB_512)
def generate_quiz_fn(req: https_fn.CallableRequest) -> Any:
    topic_id = req.data["topicId"]
    return generate_quiz(topic_id)


@https_fn.on_call(region="europe-west1", memory=options.MemoryOption.MB_512)
def summarize_fn(req: https_fn.CallableRequest) -> Any:
    topic_id = req.data["topicId"]
    return summarize(topic_id)
