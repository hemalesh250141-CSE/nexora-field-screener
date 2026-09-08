import datetime
from sqlalchemy import Column, String, Float, Integer, Boolean, DateTime, Text
from database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    badge_id = Column(String(64), unique=True, index=True, nullable=False)
    full_name = Column(String(128), nullable=False)
    hashed_password = Column(String(256), nullable=False)
    role = Column(String(32), nullable=False, default="OFFICER") # OFFICER, SUPERVISOR, ADMIN
    station_id = Column(String(64), nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

class EvidenceRecordModel(Base):
    __tablename__ = "evidence_records"

    id = Column(String(64), primary_key=True, index=True)
    case_id = Column(String(64), index=True, nullable=False)
    officer_id = Column(String(64), index=True, nullable=False)
    captured_at_utc = Column(String(64), nullable=False)
    gps_latitude = Column(Float, nullable=False)
    gps_longitude = Column(Float, nullable=False)
    gps_accuracy = Column(Float, nullable=False)
    raw_image_hash = Column(String(64), nullable=False)
    evidence_hash = Column(String(64), index=True, nullable=False)
    previous_record_hash = Column(String(64), nullable=False)
    record_hash = Column(String(64), unique=True, nullable=False)
    record_version = Column(Integer, default=1)
    analysis_status = Column(String(32), nullable=False)
    possible_matches = Column(Text, nullable=False)
    confidence = Column(String(32), nullable=False)
    delta_e = Column(Float, nullable=False)
    image_quality = Column(String(64), nullable=False)
    calibration_quality = Column(String(64), nullable=False)
    engine_version = Column(String(32), nullable=False)
    dataset_version = Column(String(32), nullable=False)
    canonical_payload = Column(Text, nullable=False)
    sync_status = Column(String(32), default="SYNCED")
    sample_color_hex = Column(String(16), nullable=True)
    reagent_used = Column(String(64), nullable=True)
    officer_notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

class ReferenceProfileModel(Base):
    __tablename__ = "reference_profiles"

    id = Column(Integer, primary_key=True, index=True)
    profile_id = Column(String(64), unique=True, index=True, nullable=False)
    display_name = Column(String(128), nullable=False)
    category = Column(String(128), nullable=False)
    reagent_name = Column(String(64), nullable=False)
    functional_group_target = Column(String(128), nullable=True)
    reference_hex = Column(String(16), nullable=False)
    reference_lab = Column(Text, nullable=False)
    tolerance_delta_e = Column(Float, default=2.0)
    version = Column(String(32), default="v1.0")
    calibration_source = Column(String(128), default="NCFS-REFERENCE-LAB-2026")
    active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

class AuditEventModel(Base):
    __tablename__ = "audit_events"

    id = Column(Integer, primary_key=True, index=True)
    event_id = Column(String(64), unique=True, index=True, nullable=False)
    actor_id = Column(String(64), index=True, nullable=False)
    event_type = Column(String(64), index=True, nullable=False)
    timestamp_utc = Column(String(64), nullable=False)
    device_id = Column(String(64), nullable=False)
    related_record_id = Column(String(64), nullable=True)
    metadata_json = Column(Text, nullable=False)
    event_hash = Column(String(64), unique=True, nullable=False)
    previous_event_hash = Column(String(64), nullable=False)

class CitizenTipModel(Base):
    __tablename__ = "citizen_tips"

    id = Column(Integer, primary_key=True, index=True)
    tip_id = Column(String(64), unique=True, index=True, nullable=False)
    category = Column(String(64), nullable=False)
    description = Column(Text, nullable=False)
    optional_latitude = Column(Float, nullable=True)
    optional_longitude = Column(Float, nullable=True)
    optional_media_hash = Column(String(64), nullable=True)
    submitted_at_utc = Column(String(64), nullable=False)
    status = Column(String(32), default="SUBMITTED")
