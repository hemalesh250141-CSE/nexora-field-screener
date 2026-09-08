import sys
import os
import time
import hashlib
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

import pytest
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_health_check_returns_statutory_notice():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "HEALTHY"
    assert "statutorily mandated" in data["statutoryNotice"].lower()

def test_officer_login_success_and_failure():
    # Valid login
    resp = client.post("/auth/login", json={"badge_id": "BADGE-104", "password": "Password@123"})
    assert resp.status_code == 200
    token_data = resp.json()
    assert "access_token" in token_data
    assert token_data["role"] == "OFFICER"

    # Invalid password
    bad_resp = client.post("/auth/login", json={"badge_id": "BADGE-104", "password": "WrongPassword"})
    assert bad_resp.status_code == 401

def test_rbac_profile_modification_denied_for_officer():
    # Login as Officer
    login_resp = client.post("/auth/login", json={"badge_id": "BADGE-104", "password": "Password@123"})
    token = login_resp.json()["access_token"]

    # Try to modify reference profiles (Admin only)
    headers = {"Authorization": f"Bearer {token}"}
    resp = client.post(
        "/reference-profiles",
        headers=headers,
        json={
            "profileId": "TEST-UNAUTH-01",
            "displayName": "Unauthorized Profile",
            "category": "Test",
            "reagentName": "Marquis",
            "referenceHex": "#000000",
            "referenceLab": '{"l":0,"a":0,"b":0}',
        },
    )
    assert resp.status_code == 403  # Forbidden by RBAC

def test_evidence_ingestion_and_integrity_verification():
    # Login as Officer
    login_resp = client.post("/auth/login", json={"badge_id": "BADGE-104", "password": "Password@123"})
    token = login_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    unique_ts = int(time.time() * 1000)
    rec_id = f"EV-TEST-{unique_ts}"
    canonical = f'{{"caseId":"CASE-TEST-{unique_ts}","gps":{{"accuracy":3.4,"latitude":13.0827,"longitude":80.2707}}}}'
    evidence_hash = hashlib.sha256(canonical.encode("utf-8")).hexdigest()
    rec_hash = hashlib.sha256(f"REC_{unique_ts}".encode("utf-8")).hexdigest()

    payload = {
        "id": rec_id,
        "caseId": f"CASE-TEST-{unique_ts}",
        "officerId": "BADGE-104",
        "capturedAtUtc": "2026-09-08T15:00:00.000Z",
        "gpsLatitude": 13.0827,
        "gpsLongitude": 80.2707,
        "gpsAccuracy": 3.4,
        "rawImageHash": "a" * 64,
        "evidenceHash": evidence_hash,
        "previousRecordHash": "0" * 64,
        "recordHash": rec_hash,
        "recordVersion": 1,
        "analysisStatus": "PRESUMPTIVE",
        "possibleMatches": "[]",
        "confidence": "HIGH SIMILARITY",
        "deltaE": 0.5,
        "imageQuality": "QUALITY: GOOD",
        "calibrationQuality": "CALIBRATED",
        "engineVersion": "CIE-DE2000-v1.4",
        "referenceDatasetVersion": "DS-FORENSIC-2026.1",
        "canonicalPayload": canonical,
    }

    create_resp = client.post("/evidence", headers=headers, json=payload)
    assert create_resp.status_code == 201

    # Verify evidence
    verify_resp = client.get(f"/evidence/{rec_id}/verify", headers=headers)
    assert verify_resp.status_code == 200
    verify_data = verify_resp.json()
    assert verify_data["status"] == "INTEGRITY VERIFIED"
    assert verify_data["is_hash_valid"] is True

def test_anonymous_citizen_tip_submission():
    unique_ts = int(time.time() * 1000)
    tip_payload = {
        "tipId": f"TIP-2026-{unique_ts}",
        "category": "Suspicious Packaging / Drop",
        "description": "Unattended suspicious container near warehouse dock.",
        "optionalLatitude": 13.0850,
        "optionalLongitude": 80.2720,
        "submittedAtUtc": "2026-09-08T15:10:00.000Z",
    }

    # Anonymous submission requires no auth token
    resp = client.post("/citizen-tips", json=tip_payload)
    assert resp.status_code == 201
    data = resp.json()
    assert data["tip_id"] == f"TIP-2026-{unique_ts}"
    assert data["status"] == "SUBMITTED"
