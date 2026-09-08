from typing import Optional, List, Any
from pydantic import BaseModel

class LoginRequest(BaseModel):
    badge_id: str
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: str
    badge_id: str
    full_name: str

class UserOut(BaseModel):
    badge_id: str
    full_name: str
    role: str
    station_id: str
    is_active: bool

class EvidenceRecordCreate(BaseModel):
    id: str
    caseId: str
    officerId: str
    capturedAtUtc: str
    gpsLatitude: float
    gpsLongitude: float
    gpsAccuracy: float
    rawImageHash: str
    evidenceHash: str
    previousRecordHash: str
    recordHash: str
    recordVersion: int = 1
    analysisStatus: str
    possibleMatches: str
    confidence: str
    deltaE: float
    imageQuality: str
    calibrationQuality: str
    engineVersion: str
    referenceDatasetVersion: str
    canonicalPayload: str
    sampleColorHex: Optional[str] = None
    reagentUsed: Optional[str] = None
    officerNotes: Optional[str] = None

class EvidenceRecordOut(BaseModel):
    id: str
    case_id: str
    officer_id: str
    captured_at_utc: str
    gps_latitude: float
    gps_longitude: float
    gps_accuracy: float
    evidence_hash: str
    previous_record_hash: str
    record_hash: str
    analysis_status: str
    confidence: str
    delta_e: float
    sync_status: str
    reagent_used: Optional[str] = None

class EvidenceVerificationOut(BaseModel):
    record_id: str
    evidence_hash: str
    is_hash_valid: bool
    is_chain_intact: bool
    status: str
    statutory_disclaimer: str

class SyncBatchRequest(BaseModel):
    batchId: str
    records: List[dict]

class SyncBatchResponse(BaseModel):
    batchId: str
    status: str
    acceptedCount: int
    rejectedCount: int
    acknowledgedIds: List[str]

class ReferenceProfileCreate(BaseModel):
    profileId: str
    displayName: str
    category: str
    reagentName: str
    functionalGroupTarget: Optional[str] = None
    referenceHex: str
    referenceLab: str
    toleranceDeltaE: float = 2.0
    version: str = "v1.0"
    active: bool = True

class ReferenceProfileOut(BaseModel):
    profile_id: str
    display_name: str
    category: str
    reagent_name: str
    reference_hex: str
    tolerance_delta_e: float
    active: bool

class AuditEventOut(BaseModel):
    event_id: str
    actor_id: str
    event_type: str
    timestamp_utc: str
    device_id: str
    related_record_id: Optional[str] = None
    event_hash: str

class CitizenTipCreate(BaseModel):
    tipId: str
    category: str
    description: str
    optionalLatitude: Optional[float] = None
    optionalLongitude: Optional[float] = None
    optionalMediaHash: Optional[str] = None
    submittedAtUtc: str

class CitizenTipOut(BaseModel):
    tip_id: str
    category: str
    description: str
    submitted_at_utc: str
    status: str
