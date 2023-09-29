import logging
from typing import List, Optional
from firebase_admin import firestore
import google.cloud.firestore
import vertexai
from langchain.prompts import PromptTemplate
from langchain.llms import VertexAI
from langchain.output_parsers import PydanticOutputParser
from langchain.pydantic_v1 import BaseModel, Field


class Question(BaseModel):
    """
    `questions` children
    """

    type: str = Field(
        description="the type of question (multiple_choice, multiple_choice_multi, connect_terms or free_text)"
    )
    question: Optional[str] = Field(description="the question")
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
        description="the exact correct answer in case of multiple_choice and free_text. in case of connect_terms, it's the combination of the index of the left and write column with a hyphen, separated by a comma eg. '1-3,2-2,3-1'. in case of multiple_choice_multi, it's all correct answers separated by a comma eg. 'first correct answer, second correct answer'. this field is always required!"
    )


class Topic(BaseModel):
    name: str = Field(description="the name of the topic")
    description: str = Field(
        description="a short description of the content of the topic"
    )
    language: str = Field(description="the language of the provided input")
    questions: List[Question] = Field(default=[], description="the list of questions")


def generate_quiz(topic_id: str):
    firestore_client: google.cloud.firestore.Client = firestore.client()

    try:
        firestore_client.collection("topics").document(topic_id).update(
            {"quizStatus": "generating"}
        )

        files = firestore_client.collection(f"topics/{topic_id}/files").stream()

        fulltext = ""
        for document in files:
            fulltext += document.get("text") + "\n"

        template = """You are a world class algorithm for generating quizzes in a structured format.

{format_instructions}

You will receive a piece of text and you will need to create a quiz based on that text (in the same language). You will also detect the language of the text and provide a quiz title and short description.
The quiz you generate will have multiple questions (at least 5) and you can have 4 types of questions: 
    1.Multiple choice (multiple_choice): provide at least 3 choices per question and provide the correct answer (exact).
    1.Multiple choice with multiple answers (multiple_choice_multi): provide at least 3 choices per question and provide the correct answers, separated by commas (a potential correct value for answer could be 'foo,bar,test').
    2.Connect relevant terms (connect_terms): at least 3 terms in a random order in 1 column and at least 3 terms in a random order in the other column. The person that takes the test must select a matching term in each column.
    3.A free text question (free_text). Make sure to ask a question of which the answer can be found in the provided text, and make sure to provide the correct answer in the answer field. 'What do you think of ...?' is not a good question!
For each question, you also need to provide the correct answer. Make sure that the correct answer is exactly the same as the value of the choice (for connect_terms it should format a string with the indexes of the answers for each column '1-3,2-2,3-1'). The question should be concise and clear. The question should not list possible choices.

You also need to detect the language of the text (in the \'language field\'). The values of the name, description, questions, choices, answers should all be in the same language as the input text.
Make sure that all output is in the same language as the input text (all field values).
Make sure to only answer with a valid JSON in the correct format.

INPUT: "{input}"

JSON RESPONSE:"""

        output_parser = PydanticOutputParser(pydantic_object=Topic)
        format_instructions = output_parser.get_format_instructions()
        prompt = PromptTemplate(
            input_variables=["input"],
            partial_variables={"format_instructions": format_instructions},
            template=template,
        )
        final_prompt = prompt.format(input=fulltext)
        logging.debug(final_prompt)

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

        logging.debug("res_text", res_text)

        res = output_parser.parse(res_text)

        logging.debug(res)

        # res_obj = Topic(**res)
        # print("res", res)

        for question in res.questions:
            logging.debug(question)
            firestore_client.collection(f"topics/{topic_id}/questions").add(
                dict(question)
            )

        firestore_client.collection("topics").document(topic_id).update(
            {
                "quizStatus": "done",
                "name": res.name,
                "description": res.description,
            }
        )

        logging.debug("done")

        return {"done": True}

    except Exception as error:
        error_name = type(error).__name__
        logging.error(
            f"Error while generating quiz: {error_name} {error} {error.__traceback__}"
        )
        firestore_client.collection("topics").document(topic_id).update(
            {"quizStatus": f"error: {error_name}"}
        )
