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
from langchain.prompts import PromptTemplate
from langchain.llms import VertexAI
from langchain.output_parsers import PydanticOutputParser
from langchain.pydantic_v1 import BaseModel, Field
from langchain.chains.summarize import load_summarize_chain
from langchain.text_splitter import RecursiveCharacterTextSplitter
import transformers


def summarize(topic_id: str):
    firestore_client: google.cloud.firestore.Client = firestore.client()

    try:
        firestore_client.collection("topics").document(topic_id).update(
            {"summaryStatus": "generating"}
        )

        files = firestore_client.collection(f"topics/{topic_id}/files").stream()

        fulltext = ""
        for document in files:
            fulltext += document.get("text") + "\n"

        # Get your splitter ready
        text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=1500, chunk_overlap=50
        )

        # Split your docs into texts
        texts = text_splitter.create_documents([fulltext])

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

        logging.debug(summary)

        return {"done": True}

    except Exception as error:
        error_name = type(error).__name__
        logging.error(
            f"Error while generating summary:", error_name, error, error.__traceback__
        )
        firestore_client.collection("topics").document(topic_id).update(
            {"summaryStatus": f"error: {error_name}"}
        )
