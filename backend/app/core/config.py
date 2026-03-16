from pydantic_settings import BaseSettings
from functools import lru_cache
from typing import List

class Settings(BaseSettings):
    PROJECT_NAME: str = "Resumed API"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"

    # Google Cloud
    GOOGLE_PROJECT_ID: str = "resumed-project"
    IDENTITY_PLATFORM_PROJECT_ID: str = "resumed-project"

    # Auth
    GOOGLE_JWKS_URL: str = "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com"
    API_AUDIENCE: str = "resumed-project" # Usually the Project ID for Firebase Auth

    # Database
    DATABASE_URL: str = "postgresql://user:password@localhost/resumed_db"

    # Gemini
    GEMINI_API_KEY: str = ""

    # CORS
    ALLOWED_ORIGINS: List[str] = ["http://localhost:3000", "https://app.resumed.com.br"]

    class Config:
        case_sensitive = True
        env_file = ".env"

@lru_cache()
def get_settings():
    return Settings()
