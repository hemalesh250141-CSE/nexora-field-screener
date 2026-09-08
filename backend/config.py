import os
from pydantic import BaseModel

class Settings(BaseModel):
    PROJECT_NAME: str = "NEXORA Forensic Evidence API"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    SECRET_KEY: str = os.getenv("NEXORA_SECRET_KEY", "NEXORA_SECURE_FORENSIC_KEY_2026_HS256_HASH_PROTECTED")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 8  # 8 hour field shift session
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./nexora_backend.db")
    ALLOWED_HOSTS: list[str] = ["*"]
    DEFAULT_DELTA_E_THRESHOLD: float = 2.0
    MANDATORY_STATUTORY_DISCLAIMER: str = (
        "Presumptive Field Screener Only — Confirmatory Lab Testing (GC-MS) Statutorily Mandated."
    )

settings = Settings()
