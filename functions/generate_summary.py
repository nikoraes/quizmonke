from datetime import datetime
import logging
from typing import List
from firebase_admin import firestore
import google.cloud.firestore
import vertexai
from langchain.prompts import PromptTemplate
from langchain.llms import VertexAI


def generate_summary(topic_id: str):
    firestore_client: google.cloud.firestore.Client = firestore.client()

    try:
        topic_ref = firestore_client.collection("topics").document(topic_id)
        topic_ref.update({"summaryStatus": "generating"})

        files = firestore_client.collection(f"topics/{topic_id}/files").stream()

        fulltext = ""
        for document in files:
            fulltext += document.get("text") + "\n"

        prompt_template = """Generate a summary of the provided input text. The summary should help to memorize the content of the provided input text. Use multiple paragraphs to improve readability. The generated summary must be in the same language as the input text!

INPUT: "{text}"

SUMMARY:"""

        prompt = PromptTemplate(
            template=prompt_template,
            input_variables=["text"],
        )
        final_prompt = prompt.format(text=fulltext)
        print(f"generate_summary - final_prompt: {final_prompt}")

        vertexai.init(project="schoolscan-4c8d8", location="us-central1")
        llm = VertexAI(
            model_name="text-bison",
            candidate_count=1,
            max_output_tokens=1024,
            temperature=0.2,
            top_p=0.8,
            top_k=40,
        )

        res_text = llm(final_prompt)

        print(f"generate_summary - res_text: {res_text}")

        topic_ref.update(
            {
                "timestamp": firestore.SERVER_TIMESTAMP,
                "summary": res_text,
                "summaryStatus": "done",
            }
        )

        return {"done": True}

    except Exception as error:
        error_name = type(error).__name__
        print(
            f"summarize - Error while generating summary: {error_name} {error} {error.__traceback__}"
        )
        firestore_client.collection("topics").document(topic_id).update(
            {"summaryStatus": f"error: {error_name}"}
        )
