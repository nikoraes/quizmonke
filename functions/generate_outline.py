from datetime import datetime
import logging
from typing import List
from firebase_admin import firestore
import google.cloud.firestore
import vertexai
from langchain.prompts import PromptTemplate
from langchain.llms import VertexAI


def generate_outline(topic_id: str):
    firestore_client: google.cloud.firestore.Client = firestore.client()

    try:
        topic_ref = firestore_client.collection("topics").document(topic_id)
        topic_ref.update({"outlineStatus": "generating"})

        files = firestore_client.collection(f"topics/{topic_id}/files").stream()

        fulltext = ""
        for document in files:
            fulltext += document.get("text") + "\n"

        prompt_template = """Generate a structured outline (markdown) for the provided INPUT. 
Make sure that the generated outline is in the same language as the INPUT.

Here's a sample of part of a structured OUTLINE:

SAMPLE OUTLINE: "
## I. Astronaut's Perspective

   A. Embracing the Unknown

      1. Facing Fear
         - Astronaut's initial apprehensions
         - **Overcoming Fear:** Emphasize the courage needed

      2. View from Space
         - Describe the awe-inspiring experience
         - _Unforgettable Moment:_ Highlight a specific view

   B. Life in Zero Gravity

      1. Adaptation
         - Discuss challenges of living without gravity
         - `Scientific Insight:` Brief explanation of zero gravity effects

## II. Celestial Phenomena

   A. Solar System Exploration

      1. Martian Landscape
         - Overview of Mars exploration"

INPUT: "{text}"

OUTLINE:"""

        prompt = PromptTemplate(
            template=prompt_template,
            input_variables=["text"],
        )
        final_prompt = prompt.format(text=fulltext)
        print(f"generate_outline - final_prompt: {final_prompt}")

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

        print(f"generate_outline - res_text: {res_text}")

        topic_ref.update(
            {
                "timestamp": firestore.SERVER_TIMESTAMP,
                "outline": res_text,
                "outlineStatus": "done",
            }
        )

        return {"done": True}

    except Exception as error:
        error_name = type(error).__name__
        print(
            f"generate_outline - Error while generating outline: {error_name} {error} {error.__traceback__}"
        )
        firestore_client.collection("topics").document(topic_id).update(
            {"outlineStatus": f"error: {error_name}"}
        )
