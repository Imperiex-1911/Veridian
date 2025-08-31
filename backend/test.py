from dotenv import load_dotenv
import os

dotenv_path = r"C:\Home_audit\Veridian\backend\.env"
print("Looking for:", dotenv_path)

if not os.path.exists(dotenv_path):
    print("❌ .env file NOT found")
else:
    print("✅ .env file exists")

load_dotenv(dotenv_path)

print("Loaded:", os.getenv("GOOGLE_APPLICATION_CREDENTIALS"))
