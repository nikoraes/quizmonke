from datetime import datetime
import logging
from typing import List
from firebase_admin import firestore
import google.cloud.firestore
import vertexai
from langchain.prompts import PromptTemplate
from langchain.llms import VertexAI

from langchain.output_parsers import PydanticOutputParser
from langchain.pydantic_v1 import BaseModel, Field


class Topic(BaseModel):
    language: str = Field(
        description="the language of the provided input, 2-letter code"
    )
    name: str = Field(
        description="the name of the topic (max 20 characters, same language as the input) "
    )
    description: str = Field(
        description="a short description of the content of the topic (max 80 characters, same language as the input)"
    )
    tags: List[str] = Field(
        description="a list of tags (one word each) that are related to the input (max 5 tags, same language as the input)"
    )


def generate_topic_details(topic_id: str):
    firestore_client: google.cloud.firestore.Client = firestore.client()

    try:
        topic_ref = firestore_client.collection("topics").document(topic_id)
        topic_ref.update({"status": "generating"})

        files = firestore_client.collection(f"topics/{topic_id}/files").stream()

        fulltext = ""
        for document in files:
            fulltext += document.get("text") + "\n"

        prompt_template = """Detect the language, generate a name, a short description and a list of tags for the provided input. Everything should be in the same language as the input.

**INPUT:**
"{text}"

**JSON RESPONSE:**"""

        output_parser = PydanticOutputParser(pydantic_object=Topic)
        format_instructions = output_parser.get_format_instructions()
        prompt = PromptTemplate(
            template=prompt_template,
            format_instructions=format_instructions,
            input_variables=["text"],
        )
        final_prompt = prompt.format(text=fulltext)
        print(f"generate_topic_details - final prompt: {final_prompt}")

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

        print(f"generate_quiz - res_text: {res_text}")

        res = output_parser.parse(res_text)

        print(f"generate_quiz - res: {res}")

        topic_ref.update(
            {
                "timestamp": firestore.SERVER_TIMESTAMP,
                "name": res.name,
                "language": res.language,
                "description": res.description,
                "tags": res.tags,
                "status": "done",
            }
        )

        return {"done": True}

    except Exception as error:
        error_name = type(error).__name__
        print(
            f"generate_topic_details - Error while generating topic details: {error_name} {error} {error.__traceback__}"
        )
        firestore_client.collection("topics").document(topic_id).update(
            {"status": f"error: {error_name}"}
        )
