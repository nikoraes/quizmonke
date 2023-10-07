import logging
from typing import List, Optional
from firebase_admin import firestore
import google.cloud.firestore
import vertexai
from langchain.prompts import PromptTemplate
from langchain.llms import VertexAI
from langchain.output_parsers import PydanticOutputParser
from langchain.pydantic_v1 import BaseModel, Field

vertexai.init(project="schoolscan-4c8d8", location="us-central1")


def check_answer_free_text(
    topic_id: str, question: str, answer: str, provided_answer: str
):
    firestore_client: google.cloud.firestore.Client = firestore.client()

    llm = VertexAI(
        model_name="text-bison@001",
        candidate_count=1,
        max_output_tokens=1024,
        temperature=0.2,
        top_p=0.8,
        top_k=40,
    )

    template = """You will receive a question, the correct answer and an answer provided by the user. You need to check whether the provided answer is correct. 
    In case the correct answer doesn't provide enough information to verify the provided answer, you need to respond that you need more context. 
    You can only respond with the following text (nothing else):
    true: The answer is correct
    false: The answer is wrong
    need_context:  You need more context

    QUESTION: {question}

    CORRECT ANSWER: {answer}

    PROVIDED ANSWER: {provided_answer}

    RESPONSE:"""

    prompt = PromptTemplate(
        input_variables=["question", "answer", "provided_answer"],
        template=template,
    )
    final_prompt = prompt.format(
        question=question, answer=answer, provided_answer=provided_answer
    )

    res = llm(final_prompt)

    print(res)

    return res
