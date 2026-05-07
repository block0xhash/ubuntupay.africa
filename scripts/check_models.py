
import os
from google import genai
from dotenv import load_dotenv

load_dotenv()

def list_gemini_models():
    api_key = os.getenv("GEMINI_API_KEY")
    client = genai.Client(api_key=api_key)

    print("📡 Fetching available models...")
    try:
        # Just list the names to avoid attribute errors
        for m in client.models.list():
            print(f"📍 {m.name}")
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    list_gemini_models()
