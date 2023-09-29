from firebase_admin import initialize_app
from generate_quiz import generate_quiz

initialize_app()

topic_id = "TIqIjT9DgvUNmhvrEwpq"

generate_quiz(topic_id)
