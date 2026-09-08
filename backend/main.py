import os
import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from config import settings
import database
import models
import services
from api_routes import router

# 1. Initialize Tables
database.Base.metadata.create_all(bind=database.engine)

# 2. Seed Initial Forensic Accounts & Reference Standards
db = database.SessionLocal()
try:
    services.seed_initial_data(db)
finally:
    db.close()

# 3. Create FastAPI Application Instance
app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description=(
        "NEXORA Forensic Evidence & Spot Screening API — "
        f"{settings.MANDATORY_STATUTORY_DISCLAIMER}"
    ),
)

# 4. Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_HOSTS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 5. Attach API Routes
app.include_router(router)

# 6. Mount Static Directory & Serve Interactive Forensic Web Preview
static_dir = os.path.join(os.path.dirname(__file__), "static")
if os.path.exists(static_dir):
    app.mount("/static", StaticFiles(directory=static_dir), name="static")

    @app.get("/", include_in_schema=False)
    async def serve_preview():
        return FileResponse(os.path.join(static_dir, "index.html"))

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=False)
