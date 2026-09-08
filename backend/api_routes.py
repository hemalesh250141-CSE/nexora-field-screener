import json
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
import database
import models
import schemas
import security
import services
from config import settings

router = APIRouter()

# ==========================================
# 1. AUTHENTICATION & SESSIONS
# ==========================================

@router.post("/auth/login", response_model=schemas.Token)
def login(form_data: schemas.LoginRequest, db: Session = Depends(database.get_db)):
    user = db.query(models.User).filter(models.User.badge_id == form_data.badge_id.upper()).first()
    if not user or not security.verify_password(form_data.password, user.hashed_password):
        services.log_audit_event(
            db=db,
            actor_id=form_data.badge_id,
            event_type="LOGIN_FAILURE",
            metadata={"reason": "Invalid credentials"},
        )
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect Badge ID or password",
        )

    access_token = security.create_access_token(
        data={"sub": user.badge_id, "role": user.role, "stationId": user.station_id}
    )

    services.log_audit_event(
        db=db,
        actor_id=user.badge_id,
        event_type="LOGIN_SUCCESS",
        metadata={"role": user.role, "station": user.station_id},
    )

    return {
        "access_token": access_token,
        "token_type": "bearer",
        "role": user.role,
        "badge_id": user.badge_id,
        "full_name": user.full_name,
    }

@router.get("/auth/me", response_model=schemas.UserOut)
def read_current_user(current_user: models.User = Depends(security.get_current_user)):
    return schemas.UserOut(
        badge_id=current_user.badge_id,
        full_name=current_user.full_name,
        role=current_user.role,
        station_id=current_user.station_id,
        is_active=current_user.is_active,
    )

# ==========================================
# 2. EVIDENCE VAULT & VERIFICATION
# ==========================================

@router.post("/evidence", response_model=schemas.EvidenceRecordOut, status_code=status.HTTP_201_CREATED)
def create_evidence(
    record: schemas.EvidenceRecordCreate,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(security.require_roles(["OFFICER", "ADMIN"])),
):
    # Check duplicate
    existing = db.query(models.EvidenceRecordModel).filter(models.EvidenceRecordModel.id == record.id).first()
    if existing:
        return existing

    # Verify canonical hash on arrival
    is_valid = services.verify_evidence_payload(record.canonicalPayload, record.evidenceHash)
    if not is_valid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Evidence rejected: Canonical SHA-256 payload does not match sealed hash.",
        )

    db_record = models.EvidenceRecordModel(
        id=record.id,
        case_id=record.caseId,
        officer_id=current_user.badge_id,
        captured_at_utc=record.capturedAtUtc,
        gps_latitude=record.gpsLatitude,
        gps_longitude=record.gpsLongitude,
        gps_accuracy=record.gpsAccuracy,
        raw_image_hash=record.rawImageHash,
        evidence_hash=record.evidenceHash,
        previous_record_hash=record.previousRecordHash,
        record_hash=record.recordHash,
        record_version=record.recordVersion,
        analysis_status=record.analysisStatus,
        possible_matches=record.possibleMatches,
        confidence=record.confidence,
        delta_e=record.deltaE,
        image_quality=record.imageQuality,
        calibration_quality=record.calibrationQuality,
        engine_version=record.engineVersion,
        dataset_version=record.referenceDatasetVersion,
        canonical_payload=record.canonicalPayload,
        sync_status="SYNCED",
        sample_color_hex=record.sampleColorHex,
        reagent_used=record.reagentUsed,
        officer_notes=record.officerNotes,
    )

    db.add(db_record)
    db.commit()
    db.refresh(db_record)

    services.log_audit_event(
        db=db,
        actor_id=current_user.badge_id,
        event_type="EVIDENCE_INGESTED",
        related_record_id=db_record.id,
        metadata={"caseId": db_record.case_id, "evidenceHash": db_record.evidence_hash},
    )

    return db_record

@router.get("/evidence", response_model=List[schemas.EvidenceRecordOut])
def list_evidence(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(security.get_current_user),
):
    if current_user.role == "OFFICER":
        # Officer views own tests or assigned station
        records = db.query(models.EvidenceRecordModel).filter(models.EvidenceRecordModel.officer_id == current_user.badge_id).all()
    else:
        # Supervisor and Admin view all authorized records
        records = db.query(models.EvidenceRecordModel).all()
    return records

@router.get("/evidence/{id}", response_model=schemas.EvidenceRecordOut)
def get_evidence_detail(
    id: str,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(security.get_current_user),
):
    rec = db.query(models.EvidenceRecordModel).filter(models.EvidenceRecordModel.id == id).first()
    if not rec:
        raise HTTPException(status_code=404, detail="Evidence record not found in vault")
    return rec

@router.get("/evidence/{id}/verify", response_model=schemas.EvidenceVerificationOut)
def verify_evidence_integrity(
    id: str,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(security.get_current_user),
):
    rec = db.query(models.EvidenceRecordModel).filter(models.EvidenceRecordModel.id == id).first()
    if not rec:
        raise HTTPException(status_code=404, detail="Evidence record not found in vault")

    is_valid = services.verify_evidence_payload(rec.canonical_payload, rec.evidence_hash)

    status_str = "INTEGRITY VERIFIED" if is_valid else "INTEGRITY FAILURE"

    services.log_audit_event(
        db=db,
        actor_id=current_user.badge_id,
        event_type="EVIDENCE_VERIFIED",
        related_record_id=rec.id,
        metadata={"valid": is_valid, "status": status_str},
    )

    return {
        "record_id": rec.id,
        "evidence_hash": rec.evidence_hash,
        "is_hash_valid": is_valid,
        "is_chain_intact": is_valid,
        "status": status_str,
        "statutory_disclaimer": settings.MANDATORY_STATUTORY_DISCLAIMER,
    }

# ==========================================
# 3. IDEMPOTENT OFFLINE SYNCHRONIZATION
# ==========================================

@router.post("/sync", response_model=schemas.SyncBatchResponse)
def sync_offline_batch(
    batch: schemas.SyncBatchRequest,
    db: Session = Depends(database.get_db),
):
    accepted = 0
    rejected = 0
    acked_ids = []

    for item in batch.records:
        rec_id = item.get("id")
        if not rec_id:
            rejected += 1
            continue

        existing = db.query(models.EvidenceRecordModel).filter(models.EvidenceRecordModel.id == rec_id).first()
        if existing:
            # Idempotent re-acknowledgement
            accepted += 1
            acked_ids.append(rec_id)
            continue

        try:
            payload = item.get("canonicalPayload", "")
            ev_hash = item.get("evidenceHash", "")
            if not services.verify_evidence_payload(payload, ev_hash):
                rejected += 1
                continue

            db_record = models.EvidenceRecordModel(
                id=rec_id,
                case_id=item.get("caseId", "UNKNOWN"),
                officer_id=item.get("officerId", "FIELD_SYNC"),
                captured_at_utc=item.get("capturedAtUtc", ""),
                gps_latitude=float(item.get("gpsLatitude", 0.0)),
                gps_longitude=float(item.get("gpsLongitude", 0.0)),
                gps_accuracy=float(item.get("gpsAccuracy", 0.0)),
                raw_image_hash=item.get("rawImageHash", ""),
                evidence_hash=ev_hash,
                previous_record_hash=item.get("previousRecordHash", ""),
                record_hash=item.get("recordHash", ""),
                record_version=int(item.get("recordVersion", 1)),
                analysis_status=item.get("analysisStatus", "INCONCLUSIVE"),
                possible_matches=json.dumps(item.get("possibleMatches", [])),
                confidence=item.get("confidence", "INCONCLUSIVE"),
                delta_e=float(item.get("deltaE", 0.0)),
                image_quality=item.get("imageQuality", "UNKNOWN"),
                calibration_quality=item.get("calibrationQuality", "UNKNOWN"),
                engine_version=item.get("engineVersion", "1.0"),
                dataset_version=item.get("referenceDatasetVersion", "1.0"),
                canonical_payload=payload,
                sync_status="SYNCED",
                sample_color_hex=item.get("sampleColorHex"),
                reagent_used=item.get("reagentUsed"),
                officer_notes=item.get("officerNotes"),
            )
            db.add(db_record)
            db.commit()
            accepted += 1
            acked_ids.append(rec_id)
        except Exception:
            db.rollback()
            rejected += 1

    services.log_audit_event(
        db=db,
        actor_id="SYNC_WORKER",
        event_type="BATCH_SYNC_PROCESSED",
        metadata={"batchId": batch.batchId, "accepted": accepted, "rejected": rejected},
    )

    return {
        "batchId": batch.batchId,
        "status": "COMPLETED",
        "acceptedCount": accepted,
        "rejectedCount": rejected,
        "acknowledgedIds": acked_ids,
    }

# ==========================================
# 4. REFERENCE PROFILES MANAGEMENT (RBAC: ADMIN)
# ==========================================

@router.get("/reference-profiles", response_model=List[schemas.ReferenceProfileOut])
def get_reference_profiles(db: Session = Depends(database.get_db)):
    return db.query(models.ReferenceProfileModel).filter(models.ReferenceProfileModel.active == True).all()

@router.post("/reference-profiles", response_model=schemas.ReferenceProfileOut, status_code=status.HTTP_201_CREATED)
def create_or_update_profile(
    profile: schemas.ReferenceProfileCreate,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(security.require_roles(["ADMIN"])),
):
    existing = db.query(models.ReferenceProfileModel).filter(models.ReferenceProfileModel.profile_id == profile.profileId).first()
    if existing:
        existing.display_name = profile.displayName
        existing.category = profile.category
        existing.reagent_name = profile.reagentName
        existing.reference_hex = profile.referenceHex
        existing.reference_lab = profile.referenceLab
        existing.tolerance_delta_e = profile.toleranceDeltaE
        existing.active = profile.active
        db.commit()
        db.refresh(existing)
        target = existing
    else:
        new_prof = models.ReferenceProfileModel(
            profile_id=profile.profileId,
            display_name=profile.displayName,
            category=profile.category,
            reagent_name=profile.reagentName,
            functional_group_target=profile.functionalGroupTarget,
            reference_hex=profile.referenceHex,
            reference_lab=profile.referenceLab,
            tolerance_delta_e=profile.toleranceDeltaE,
            version=profile.version,
            active=profile.active,
        )
        db.add(new_prof)
        db.commit()
        db.refresh(new_prof)
        target = new_prof

    services.log_audit_event(
        db=db,
        actor_id=current_user.badge_id,
        event_type="REFERENCE_PROFILE_CHANGED",
        metadata={"profileId": target.profile_id, "active": target.active},
    )

    return target

# ==========================================
# 5. SECURITY AUDIT LOG TRAIL
# ==========================================

@router.get("/audit", response_model=List[schemas.AuditEventOut])
def get_audit_trail(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(security.require_roles(["SUPERVISOR", "ADMIN"])),
):
    return db.query(models.AuditEventModel).order_by(models.AuditEventModel.id.desc()).limit(100).all()

# ==========================================
# 6. CITIZEN WATCH (PUBLIC TIP INTAKE)
# ==========================================

@router.post("/citizen-tips", response_model=schemas.CitizenTipOut, status_code=status.HTTP_201_CREATED)
def submit_citizen_tip(tip: schemas.CitizenTipCreate, db: Session = Depends(database.get_db)):
    db_tip = models.CitizenTipModel(
        tip_id=tip.tipId,
        category=tip.category,
        description=tip.description,
        optional_latitude=tip.optionalLatitude,
        optional_longitude=tip.optionalLongitude,
        optional_media_hash=tip.optionalMediaHash,
        submitted_at_utc=tip.submittedAtUtc,
        status="SUBMITTED",
    )
    db.add(db_tip)
    db.commit()
    db.refresh(db_tip)

    services.log_audit_event(
        db=db,
        actor_id="ANONYMOUS_CITIZEN",
        event_type="CITIZEN_TIP_CREATED",
        related_record_id=db_tip.tip_id,
        metadata={"category": db_tip.category},
    )

    return db_tip

@router.get("/citizen-tips", response_model=List[schemas.CitizenTipOut])
def list_citizen_tips(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(security.require_roles(["SUPERVISOR", "ADMIN"])),
):
    return db.query(models.CitizenTipModel).order_by(models.CitizenTipModel.id.desc()).all()

# ==========================================
# 7. HEALTH & STATUTORY NOTICE
# ==========================================

@router.get("/health")
def health_check():
    return {
        "status": "HEALTHY",
        "service": settings.PROJECT_NAME,
        "version": settings.VERSION,
        "statutoryNotice": settings.MANDATORY_STATUTORY_DISCLAIMER,
    }
