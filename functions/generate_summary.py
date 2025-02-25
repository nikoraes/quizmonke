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
        language = topic_ref.get(field_paths={"language"}).to_dict().get("language")

        files = firestore_client.collection(f"topics/{topic_id}/files").stream()

        fulltext = ""
        for document in files:
            fulltext += document.get("text")

        prompt_template = """Generate a summary for the provided INPUT. Use multiple paragraphs. Emphasize important words (in markdown).
The generated summary must be in the following language: "{language}"

INPUT: "{text}"

SUMMARY:"""

        prompt = PromptTemplate(
            template=prompt_template,
            input_variables=["text", "language"],
        )
        final_prompt = prompt.format(text=fulltext, language=language)
        # print(f"generate_summary - {topic_id} - final_prompt: {final_prompt}")

        vertexai.init(project="schoolscan-4c8d8", location="us-central1")
        llm = VertexAI(
            model_name="text-bison",
            max_output_tokens=1024,
            temperature=0.2,
            top_p=0.8,
            top_k=40,
            n=1,
        )

        res_text = llm(final_prompt)

        print(f"generate_summary - {topic_id} - res_text: {res_text}")

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
            f"generate_summary - {topic_id} - Error while generating summary: {error_name} {error} {error.__traceback__}"
        )
        firestore_client.collection("topics").document(topic_id).update(
            {"summaryStatus": f"error: {error_name}"}
        )
        return {"done": False, "error": error_name}
