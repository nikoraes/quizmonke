import logging
from firebase_admin import firestore
import google.cloud.firestore
import vertexai
from langchain.prompts import PromptTemplate
from langchain.llms import VertexAI

# from langchain.chains.summarize import load_summarize_chain
# from langchain.text_splitter import RecursiveCharacterTextSplitter


def summarize(topic_id: str):
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

        vertexai.init(project="schoolscan-4c8d8", location="us-central1")
        llm = VertexAI(
            model_name="text-bison@001",
            candidate_count=1,
            max_output_tokens=1024,
            temperature=0.2,
            top_p=0.8,
            top_k=40,
        )

        prompt_template = """Write a summary of the following input text in the same language. Use markdown for subtitles, bulleted or numbered lists, emphasizing, and so on. Prefer bullet points and lists over continuous text. Make sure that the summary is in the same language as the input.

**INPUT:**
"{text}"

**SUMMARY:**"""
        prompt = PromptTemplate(template=prompt_template, input_variables=["text"])
        final_prompt = prompt.format(text=fulltext)
        summary = llm(final_prompt)

        # There is a lot of complexity hidden in this one line. I encourage you to check out the video above for more detail
        # chain = load_summarize_chain(llm, chain_type="map_reduce", verbose=True)
        # summary = chain.run(texts)

        topic_ref.update({"summary": summary, "summaryStatus": "done"})

        logging.debug(summary)

        return {"done": True}

    except Exception as error:
        error_name = type(error).__name__
        logging.error(
            f"summarize - Error while generating summary: {error_name} {error} {error.__traceback__}"
        )
        firestore_client.collection("topics").document(topic_id).update(
            {"summaryStatus": f"error: {error_name}"}
        )
