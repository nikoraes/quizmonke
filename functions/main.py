import logging
from typing import Any
from firebase_admin import initialize_app
from firebase_functions import https_fn, storage_fn, options

# import google.cloud.logging

from batch_annotate import batch_annotate
from check_answer_free_text import check_answer_free_text
from generate_summary import generate_summary
from process_annotations import process_annotations
from generate_quiz import generate_quiz

# deprecated
from summarize import summarize


initialize_app()

# logging_client = google.cloud.logging.Client()
# logging_client.setup_logging()


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


# deprecated
@https_fn.on_call(region="europe-west1", memory=options.MemoryOption.MB_512)
def summarize_fn(req: https_fn.CallableRequest) -> Any:
    topic_id = req.data["topicId"]
    return summarize(topic_id)


@https_fn.on_call(region="europe-west1", memory=options.MemoryOption.MB_512)
def generate_summary_fn(req: https_fn.CallableRequest) -> Any:
    topic_id = req.data["topicId"]
    return generate_summary(topic_id)


@https_fn.on_call(region="europe-west1", memory=options.MemoryOption.MB_512)
def check_answer_free_text_fn(req: https_fn.CallableRequest) -> Any:
    topic_id = req.data["topicId"]
    question = req.data["question"]
    answer = req.data["answer"]
    provided_answer = req.data["providedAnswer"]
    return check_answer_free_text(topic_id, question, answer, provided_answer)
