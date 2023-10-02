import logging
from typing import List
from firebase_admin import firestore
import google.cloud.firestore
import vertexai
from langchain.prompts import PromptTemplate
from langchain.llms import VertexAI
from langchain.output_parsers import PydanticOutputParser
from langchain.pydantic_v1 import BaseModel, Field

# from langchain.chains.summarize import load_summarize_chain
# from langchain.text_splitter import RecursiveCharacterTextSplitter

# TODO: sep funcs for summary and outline


class TopicWithSummary(BaseModel):
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
    summary: str = Field(
        description="a summary and outline of the input (in the same language) in markdown using subtitles, bullet points, numbering, bold, italic, ... (max 1000 characters)"
    )


def generate_summary(topic_id: str):
    firestore_client: google.cloud.firestore.Client = firestore.client()

    try:
        topic_ref = firestore_client.collection("topics").document(topic_id)
        topic_ref.update({"summaryStatus": "generating"})

        # lang = ""
        # try:
        #     topic = topic_ref.get({"language"}).to_dict()
        #     logging.debug(f"summarize - language - {topic}")
        #     lang = topic["language"]
        # except:
        #     logging.warning("summarize - language not predefined")

        files = firestore_client.collection(f"topics/{topic_id}/files").stream()

        fulltext = ""
        for document in files:
            fulltext += document.get("text") + "\n"

        # Get your splitter ready
        # text_splitter = RecursiveCharacterTextSplitter(
        #     chunk_size=1500, chunk_overlap=50
        # )

        # Split your docs into texts
        # texts = text_splitter.create_documents([fulltext])

        prompt_template = """Provide a short name, the detected language of the input text, a description, a list of tags and a full summary and outline for the following input text. All output you generate should be in the same language as the input text. 
Make sure that in the outline all important points are emphasized and that the text is structured to make studying more efficient. The summary and outline should use 'markdown' for markup, but make sure that special characters are escaped and that the full response is still valid JSON.

{format_instructions}

INPUT: "{text}"

JSON RESPONSE:"""

        output_parser = PydanticOutputParser(pydantic_object=TopicWithSummary)
        format_instructions = output_parser.get_format_instructions()

        prompt = PromptTemplate(
            template=prompt_template,
            partial_variables={"format_instructions": format_instructions},
            input_variables=["text"],
        )
        final_prompt = prompt.format(text=fulltext)
        logging.debug(f"generate_summary - final_prompt: {final_prompt}")

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

        logging.debug(f"generate_summary - res_text: {res_text}")

        res = output_parser.parse(res_text)

        logging.debug(f"generate_summary - res: {res}")

        topic_ref.update(
            {
                "name": res.name,
                "language": res.language,
                "description": res.description,
                "tags": res.tags,
                "summary": res.summary,
                "summaryStatus": "done",
            }
        )

        return {"done": True}

    except Exception as error:
        error_name = type(error).__name__
        logging.error(
            f"summarize - Error while generating summary: {error_name} {error} {error.__traceback__}"
        )
        firestore_client.collection("topics").document(topic_id).update(
            {"summaryStatus": f"error: {error_name}"}
        )
