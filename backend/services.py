import json
import hashlib
import datetime
from sqlalchemy.orm import Session
import models
import security

GENESIS_HASH = "0000000000000000000000000000000000000000000000000000000000000000"

def log_audit_event(
    db: Session,
    actor_id: str,
    event_type: str,
    device_id: str = "BACKEND-SERVER-01",
    related_record_id: str = None,
    metadata: dict = None,
) -> models.AuditEventModel:
    last_event = db.query(models.AuditEventModel).order_by(models.AuditEventModel.id.desc()).first()
    prev_hash = last_event.event_hash if last_event else GENESIS_HASH

    now_utc = datetime.datetime.now(datetime.UTC).isoformat()
    meta_json = json.dumps(metadata or {}, sort_keys=True)
    event_id = f"AUD-SRV-{int(datetime.datetime.now(datetime.UTC).timestamp() * 1000)}"

    canonical = f"{event_id}|{actor_id}|{event_type}|{now_utc}|{device_id}|{related_record_id or ''}|{prev_hash}|{meta_json}"
    event_hash = hashlib.sha256(canonical.encode("utf-8")).hexdigest()

    event = models.AuditEventModel(
        event_id=event_id,
        actor_id=actor_id,
        event_type=event_type,
        timestamp_utc=now_utc,
        device_id=device_id,
        related_record_id=related_record_id,
        metadata_json=meta_json,
        event_hash=event_hash,
        previous_event_hash=prev_hash,
    )
    db.add(event)
    db.commit()
    db.refresh(event)
    return event

def verify_evidence_payload(canonical_payload: str, expected_hash: str) -> bool:
    computed = hashlib.sha256(canonical_payload.encode("utf-8")).hexdigest()
    return computed.lower() == expected_hash.lower()

def seed_initial_data(db: Session):
    # 1. Seed Users if not present
    if not db.query(models.User).first():
        users_to_seed = [
            models.User(
                badge_id="BADGE-104",
                full_name="Officer K. Sharma",
                hashed_password=security.hash_password("Password@123"),
                role="OFFICER",
                station_id="ZONAL-NARCOTICS-BUREAU-04",
            ),
            models.User(
                badge_id="SUPER-201",
                full_name="Supervisor R. Menon",
                hashed_password=security.hash_password("Super@123"),
                role="SUPERVISOR",
                station_id="CENTRAL-FORENSICS-HQ",
            ),
            models.User(
                badge_id="ADMIN-001",
                full_name="Forensic Director V. Rao",
                hashed_password=security.hash_password("Admin@123"),
                role="ADMIN",
                station_id="NATIONAL-STANDARDS-HQ",
            ),
        ]
        db.add_all(users_to_seed)
        db.commit()

    # 2. Seed Reference Profiles if not present
    if not db.query(models.ReferenceProfileModel).first():
        profiles = [
            models.ReferenceProfileModel(
                profile_id="PROF-MQ-001",
                display_name="Reference Profile 101 (Purple-Black)",
                category="Phenethylamine / Entactogen Analogue",
                reagent_name="Marquis Reagent",
                functional_group_target="Aromatic ring with methylenedioxy bridge & amine",
                reference_hex="#0F0210",
                reference_lab='{"l":1.2,"a":3.1,"b":-2.4}',
                tolerance_delta_e=2.0,
            ),
            models.ReferenceProfileModel(
                profile_id="PROF-MQ-002",
                display_name="Reference Profile 102 (Orange-Brown)",
                category="Phenethylamine / Primary Amine Stimulant",
                reagent_name="Marquis Reagent",
                functional_group_target="Primary amine on aliphatic side chain",
                reference_hex="#7E3D11",
                reference_lab='{"l":34.1,"a":24.5,"b":38.2}',
                tolerance_delta_e=2.0,
            ),
            models.ReferenceProfileModel(
                profile_id="PROF-MQ-003",
                display_name="Reference Profile 103 (Dark Red-Brown)",
                category="Phenethylamine / Secondary Amine Stimulant",
                reagent_name="Marquis Reagent",
                functional_group_target="Secondary amine on aliphatic side chain",
                reference_hex="#6E1F00",
                reference_lab='{"l":25.3,"a":34.1,"b":33.0}',
                tolerance_delta_e=2.0,
            ),
            models.ReferenceProfileModel(
                profile_id="PROF-SC-001",
                display_name="Reference Profile 601 (Bright Blue Precipitate)",
                category="Tropane Alkaloid / Tertiary Amine Standard",
                reagent_name="Scott Reagent (Cobalt Thiocyanate)",
                functional_group_target="Tertiary amine / ester complexation",
                reference_hex="#154360",
                reference_lab='{"l":27.5,"a":-5.2,"b":-21.4}',
                tolerance_delta_e=2.0,
            ),
        ]
        db.add_all(profiles)
        db.commit()
