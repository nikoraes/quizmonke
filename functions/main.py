import logging
from threading import Thread
from typing import Callable, Any, List
from firebase_admin import initialize_app, firestore
from firebase_functions import https_fn, storage_fn, options
import google.cloud.firestore


from batch_annotate import batch_annotate
from check_answer_free_text import check_answer_free_text
from generate_topic_details import generate_topic_details
from generate_outline import generate_outline
from generate_summary import generate_summary
from process_annotations import process_annotations
from generate_quiz import generate_quiz
from delete_account_data import delete_account_data


initialize_app()


def topic_request_processor(allowed_roles: list) -> Callable:
    def decorator(fn: Callable) -> Callable:
        def wrapper(req: https_fn.CallableRequest) -> Any:
            user_id = req.auth.uid
            topic_id = req.data.get("topicId")

            if not user_id or not topic_id:
                return {"error": "Invalid request"}

            firestore_client: google.cloud.firestore.Client = firestore.client()
            topic_roles = (
                firestore_client.collection("topics")
                .document(topic_id)
                .get(field_paths={"roles"})
                .to_dict()
                .get("roles")
            )
            if topic_roles[user_id] not in allowed_roles:
                return {"error": "Access denied"}

            fn(req)

        return wrapper

    return decorator


@https_fn.on_call(region="europe-west1", memory=options.MemoryOption.MB_512)
def batch_annotate_fn(req: https_fn.CallableRequest) -> Any:
    print(f"batch_annotate_fn: {req.data}")
    return topic_request_processor(allowed_roles=["owner"])(batch_annotate(req))


@https_fn.on_call(region="europe-west1", memory=options.MemoryOption.MB_512)
# @topic_request_processor(allowed_roles=["owner"])
def generate_topic_details_fn(req: https_fn.CallableRequest) -> Any:
    return topic_request_processor(allowed_roles=["owner"])(
        generate_topic_details(req.data["topicId"])
    )


@https_fn.on_call(region="europe-west1", memory=options.MemoryOption.MB_512)
# @topic_request_processor(allowed_roles=["owner"])
def generate_quiz_fn(req: https_fn.CallableRequest) -> Any:
    return topic_request_processor(allowed_roles=["owner"])(
        generate_quiz(req.data["topicId"])
    )


@https_fn.on_call(region="europe-west1", memory=options.MemoryOption.MB_512)
# @topic_request_processor(allowed_roles=["owner"])
def generate_summary_fn(req: https_fn.CallableRequest) -> Any:
    return topic_request_processor(allowed_roles=["owner"])(
        generate_summary(req.data["topicId"])
    )


@https_fn.on_call(region="europe-west1", memory=options.MemoryOption.MB_512)
# @topic_request_processor(allowed_roles=["owner"])
def generate_outline_fn(req: https_fn.CallableRequest) -> Any:
    return topic_request_processor(allowed_roles=["owner"])(
        generate_outline(req.data["topicId"])
    )


@https_fn.on_call(region="europe-west1", memory=options.MemoryOption.MB_512)
# @topic_request_processor(allowed_roles=["reader", "owner"])
def check_answer_free_text_fn(req: https_fn.CallableRequest) -> Any:
    return topic_request_processor(allowed_roles=["reader", "owner"])(
        check_answer_free_text(
            req.data.get("topicId"),
            req.data.get("question"),
            req.data.get("answer"),
            req.data.get("providedAnswer"),
        )
    )


@https_fn.on_call(region="europe-west1", memory=options.MemoryOption.MB_512)
def delete_account_data_fn(req: https_fn.CallableRequest) -> Any:
    user_id = req.auth.uid
    return delete_account_data(user_id)


@storage_fn.on_object_finalized(
    region="europe-west1", memory=options.MemoryOption.MB_512
)
def process_annotations_fn(
    event: storage_fn.CloudEvent[storage_fn.StorageObjectData],
):
    annotations_res = process_annotations(event)
    if annotations_res["done"]:
        topic_id = str(annotations_res["topicId"])
        print(f"process_annotations_fn - Annotations processed: {topic_id}")
    elif annotations_res["skip"]:
        # skip
        return
    else:
        print(
            f"process_annotations_fn - Failed processing annotations: {annotations_res['error']}"
        )
        return

    # This also extracts the language, which is needed for the others
    topic_details_res = generate_topic_details(topic_id)
    if topic_details_res["done"]:
        print(f"process_annotations_fn - Topic details generated: {topic_id}")
    else:
        print(
            f"process_annotations_fn - Topic details failed: {topic_id} - Error: {topic_details_res['error']}"
        )

    def questions_thread():
        quiz_res = generate_quiz(topic_id)
        if quiz_res["done"]:
            print(f"process_annotations_fn - Quiz generated: {topic_id}")
        else:
            print(
                f"process_annotations_fn - Quiz generation failed: {topic_id} - Error: {quiz_res['error']}"
            )

    def summary_thread():
        summ_res = generate_summary(topic_id)
        if summ_res["done"]:
            print(f"process_annotations_fn - Summary generated: {topic_id}")
        else:
            print(
                f"process_annotations_fn - Summary generation failed: {topic_id} - Error: {summ_res['error']}"
            )

    def outline_thread():
        outline_res = generate_outline(topic_id)
        if outline_res["done"]:
            print(f"process_annotations_fn - Outline generated: {topic_id}")
        else:
            print(
                f"process_annotations_fn - Outline generation failed: {topic_id} - Error: {outline_res['error']}"
            )

    threads: List[Thread] = []
    # create the threads
    threads.append(Thread(target=questions_thread))
    threads.append(Thread(target=summary_thread))
    threads.append(Thread(target=outline_thread))
    # start the threads
    [t.start() for t in threads]
    # wait for the threads to finish
    [t.join() for t in threads]
