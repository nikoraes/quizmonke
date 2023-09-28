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

initialize_app()


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


def process_annotations(
    event: storage_fn.CloudEvent[storage_fn.StorageObjectData],
):
    firestore_client: google.cloud.firestore.Client = firestore.client()

    bucket_name = event.data.bucket
    file_path = pathlib.PurePath(event.data.name)

    print(str(file_path))

    if "annotations" not in str(file_path):
        return

    topic_id = str(file_path).split("/")[1]

    bucket = storage.bucket(bucket_name)
    blob = bucket.blob(str(file_path))
    annotation_responses = json.loads(blob.download_as_string())

    print(annotation_responses)

    for res in annotation_responses["responses"]:
        # store in db
        firestore_client.collection(f"topics/{topic_id}/files").add(
            {
                "uri": res["context"]["uri"],
                "text": res["fullTextAnnotation"]["text"],
            }
        )

    firestore_client.collection("topics").document(topic_id).update(
        {"extractStatus": "done"}
    )

    return topic_id


class Question(BaseModel):
    """
    `questions` children
    """

    type: str = Field(
        description="the type of question (multiple_choice, free_text or connect_terms)"
    )
    question: str = Field(description="the question")
    choices: Optional[List[str]] = Field(
        description="the choices for a multiple_choice question (only include field for multiple_choice questions), should have at least 3 values"
    )
    left_column: Optional[List[str]] = Field(
        description="the left column for a connect_terms question (only include field for connect_terms questions), should have at least 3 values"
    )
    right_column: Optional[List[str]] = Field(
        description="the right column for a connect_terms question (only include field for connect_terms questions), should have at least 3 values (same amount as left column)"
    )
    answer: str = Field(
        description="the exact correct answer in case of multiple_choice and free_text, in case of connect_terms, it's the combination of the index of the left and write column with a hyphen, separated by a comma eg. '1-3,2-2,3-1'. this field is always required!"
    )


class Topic(BaseModel):
    name: str = Field(description="the name of the topic")
    description: str = Field(
        description="a short description of the content of the topic"
    )
    language: str = Field(description="the language of the provided input")
    questions: List[Question]


def generate_quiz(topic_id: str):
    firestore_client: google.cloud.firestore.Client = firestore.client()

    try:
        firestore_client.collection("topics").document(topic_id).update(
            {"quizStatus": "generating"}
        )

        files = firestore_client.collection(f"topics/{topic_id}/files").stream()

        fulltext = ""

        for file in files:
            # add to total text
            file_dict = file.to_dict()
            fulltext += "\n" + file_dict["text"]

        template = """You are a world class algorithm for generating quizzes in structured formats.
You will receive a piece of text and you will need to create a quiz based on that text (in the same language). You will also detect the language of the text and provide a quiz title and short description.

The quiz you generate will have multiple questions (at least 5) and you can have 3 types of questions: 
    1.Multiple choice (multiple_choice): provide at least 3 choices per question and provide the correct answer (exact).
    2.Connect relevant terms (connect_terms): at least 3 terms in a random order in 1 column and at least 3 terms in a random order in the other column. The person that takes the test must select a matching term in each column.
    3.A free text question (free_text). Make sure to ask a question of which the answer can be found in the provided text, and make sure to provide the correct answer in the answer field. 'What do you think of ...?' is not a good question!
    
For each question, you also need to provide the correct answer. Make sure that the correct answer is exactly the same as the value of the choice (for connect_terms it should format a string with the indexes of the answers for each column '1-3,2-2,3-1'). The question should be concise and clear. The question should not list possible choices.
    
You also need to detect the language of the text (in the \'language field\'). The values of the name, description, questions, choices, answers should all be in the same language as the input text.

Make sure that all output is in the same language as the input text (all field values).

Make sure to only answer with a valid JSON in the correct format.

{format_instructions}

Input: {input} 

Formatted response: """

        output_parser = PydanticOutputParser(pydantic_object=Topic)
        format_instructions = output_parser.get_format_instructions()
        prompt = PromptTemplate(
            input_variables=["input"],
            partial_variables={"format_instructions": format_instructions},
            template=template,
        )
        final_prompt = prompt.format(input=fulltext)
        print(final_prompt)

        vertexai.init(project="schoolscan-4c8d8", location="us-central1")
        llm = VertexAI(
            model_name="text-bison@001",
            candidate_count=1,
            max_output_tokens=1024,
            temperature=0.2,
            top_p=0.8,
            top_k=40,
        )

        res_text = llm(final_prompt)

        # print(os.environ.get("OPENAI_API_KEY"))
        # llm = ChatOpenAI(openai_api_key=os.environ.get("OPENAI_API_KEY"))
        # chain = create_structured_output_chain(json_schema, llm, prompt, verbose=True)
        # res = chain.run(fulltext)

        # prompt = PromptTemplate.from_template(template)
        # prompt_text = prompt.format(text=fulltext)
        # print(prompt_text)

        # res = llm(prompt_text)

        print(res_text)
        res = json.loads(res_text)  # output_parser.parse(res_text)

        print(res)

        for question in res["questions"]:
            firestore_client.collection(f"topics/{topic_id}/questions").add(question)

        firestore_client.collection("topics").document(topic_id).update(
            {
                "quizStatus": "done",
                "name": res["name"],
                "description": res["description"],
            }
        )

        print("done")

        return {"done": True}

    except Exception as error:
        error_name = type(error).__name__
        print(f"Error {error_name} while generating quiz:", error)
        firestore_client.collection("topics").document(topic_id).update(
            {"quizStatus": f"error: {error_name}"}
        )


def summarize(topic_id: str):
    firestore_client: google.cloud.firestore.Client = firestore.client()

    try:
        firestore_client.collection("topics").document(topic_id).update(
            {"summaryStatus": "generating"}
        )

        files = firestore_client.collection(f"topics/{topic_id}/files").stream()

        texts = []

        for file in files:
            # add to total text
            file_dict = file.to_dict()
            texts += texts.append(file_dict["text"])

        # Get your splitter ready
        text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=1500, chunk_overlap=50
        )

        # Split your docs into texts
        texts = text_splitter.split_documents(texts)

        vertexai.init(project="schoolscan-4c8d8", location="us-central1")
        llm = VertexAI(
            model_name="text-bison@001",
            candidate_count=1,
            max_output_tokens=1024,
            temperature=0.2,
            top_p=0.8,
            top_k=40,
        )

        # There is a lot of complexity hidden in this one line. I encourage you to check out the video above for more detail
        chain = load_summarize_chain(llm, chain_type="map_reduce", verbose=True)
        summary = chain.run(texts)

        firestore_client.collection("topics").document(topic_id).update(
            {"summaryStatus": "done"}
        )

        print(summary)

        return {"done": True}

    except Exception as error:
        error_name = type(error).__name__
        print(f"Error {error_name} while generating summary:", error)
        firestore_client.collection("topics").document(topic_id).update(
            {"summaryStatus": f"error: {error_name}"}
        )


@https_fn.on_call(region="europe-west1", memory=options.MemoryOption.MB_512)
def batch_annotate_fn(req: https_fn.CallableRequest) -> Any:
    print(f"batch_annotate_fn: {req.data}")
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
    print(f"process_annotations_fn - Annotations processed: {topic_id}")
    generate_quiz(topic_id)
    print(f"process_annotations_fn - Quiz Generated: {topic_id}")
    summarize(topic_id)
    print(f"process_annotations_fn - Summary Generated: {topic_id}")


@https_fn.on_call(region="europe-west1", memory=options.MemoryOption.MB_512)
def generate_quiz_fn(req: https_fn.CallableRequest) -> Any:
    topic_id = req.data["topicId"]
    return generate_quiz(topic_id)


@https_fn.on_call(region="europe-west1", memory=options.MemoryOption.MB_512)
def summarize_fn(req: https_fn.CallableRequest) -> Any:
    topic_id = req.data["topicId"]
    return summarize(topic_id)
