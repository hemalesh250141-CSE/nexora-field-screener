# NEXORA: Digital Field Testing Companion
### Offline-First Native Mobile System for Authorized Field Presumptive Screening and Tamper-Evident Evidence Management

---

> [!IMPORTANT]
> ### STATUTORY FORENSIC NOTICE & SCIENTIFIC PRINCIPLE
> **"Presumptive Field Screener Only — Confirmatory Lab Testing (GC-MS) Statutorily Mandated."**
>
> NEXORA operates strictly under the scientific principle that chemical spot colourimetry is **presumptive field screening only**. 
> - The application **never** states or displays `"Drug confirmed"` or claims definitive chemical identification.
> - The system outputs **`"PRESUMPTIVE RESULT"`** alongside **`"Possible matching reference profiles"`** ranked by mathematical colour correspondence.
> - The application utilizes safe, synthetic, non-controlled reference standards derived from calibrated spectrophotometric standards. It contains **no** recipes, quantities, preparation procedures, or operational instructions for controlled substances or reagent chemicals.

---

## Table of Contents
1. [Problem Statement & Background](#problem-statement--background)
2. [Architectural Overview](#architectural-overview)
3. [Technology Stack](#technology-stack)
4. [Color Science & CIEDE2000 Engine](#color-science--ciede2000-engine)
5. [Cryptographic Chain of Custody & Tamper Evident Sealing](#cryptographic-chain-of-custody--tamper-evident-sealing)
6. [Dual-Portal Access (Officer RBAC & Citizen Watch)](#dual-portal-access-officer-rbac--citizen-watch)
7. [Offline-First Resilience & Sync Queue](#offline-first-resilience--sync-queue)
8. [SIH Judge 3–5 Minute Demonstration Flow](#sih-judge-35-minute-demonstration-flow)
9. [Project Directory Structure](#project-directory-structure)
10. [Setup and Installation](#setup-and-installation)
11. [Running the System](#running-the-system)
12. [Automated Test Suite Verification](#automated-test-suite-verification)
13. [Limitations & Production Hardening](#limitations--production-hardening)

---

## 1. Problem Statement & Background

Law-enforcement personnel conducting presumptive narcotics spot tests in the field face three critical operational challenges:
1. **Subjective Interpretation & Environmental Bias**: Ambient field illumination (harsh sun, sodium vapor, dim light) and human color perception bias cause misinterpretation of subtle spot reactions.
2. **Chain of Custody Vulnerability**: Traditional field test records rely on paper logs or unsealed photos, leaving evidence vulnerable to spoliation claims or modification disputes in judicial proceedings.
3. **Connectivity Dead-Zones**: Field operations frequently occur in areas with poor or zero cellular reception (forests, basements, highway checkpoints), where cloud-only tools fail.

**NEXORA** solves these challenges through:
- An objective **client-side computer vision pipeline** utilizing physical neutral-gray calibration to normalize ambient lighting and calculate Sharma-Wu-Dalal **CIEDE2000 ($\Delta E_{00}$)** perceptual color distances.
- An immutable **cryptographic chain of custody** combining deterministic canonical JSON serialization, raw image hashing, GPS hardware coordinates, UTC timestamps, and append-only hash chains.
- An **offline-first local database** with background synchronization queueing and exponential backoff retry policies.

---

## 2. Architectural Overview

```
                      +---------------------------------------+
                      |   DUAL-PORTAL ENTRY INTERFACE         |
                      +-------------------+-------------------+
                                          |
                 +------------------------+------------------------+
                 |                                                 |
                 v                                                 v
   [ A. OFFICER PORTAL ]                             [ B. CITIZEN WATCH PORTAL ]
   - Badge ID & Passcode                             - Fully Anonymous Tips
   - RBAC: Officer, Supervisor, Admin               - Zero Identity Harvesting
   - Field Tests, Vault, Maps, Logs                 - Encrypted Community Telemetry
                 |                                                 |
                 v                                                 |
   +-------------------------------+                               |
   | FIELD CAPTURE PIPELINE        |                               |
   | - 5-Frame Burst Averaging     |                               |
   | - Neutral Gray Calibration    |                               |
   | - Image Quality Gates         |                               |
   +---------------+---------------+                               |
                   |                                               |
                   v                                               |
   +-------------------------------+                               |
   | COLOR SCIENCE ENGINE          |                               |
   | - sRGB -> Linear RGB          |                               |
   | - CIE XYZ (D65 Illuminant)    |                               |
   | - CIELAB Standard             |                               |
   | - Sharma-Wu-Dalal CIEDE2000   |                               |
   | - Multi-Profile Ranking       |                               |
   | - Inconclusive Gate (ΔE > 2.0)|                               |
   +---------------+---------------+                               |
                   |                                               |
                   v                                               |
   +-------------------------------+                               |
   | CRYPTOGRAPHIC SEALING         |                               |
   | - Canonical JSON Payload      |                               |
   | - SHA-256 Evidence Seal       |                               |
   | - Append-Only Hash Chain Link |                               |
   +---------------+---------------+                               |
                   |                                               |
                   v                                               |
   +-------------------------------+                               |
   | ENCRYPTED LOCAL VAULT         |                               |
   | - PENDING_SYNC Queue          |                               |
   | - Immutable Audit Trail       |                               |
   +---------------+---------------+                               |
                   |                                               |
                   | (When network available)                      |
                   v                                               v
   +---------------------------------------------------------------+
   |                      FASTAPI BACKEND API                      |
   | - Server-side SHA-256 Hash Re-verification                    |
   | - Idempotent Batch Sync (/sync)                               |
   | - Role-Based Access Control Middleware (JWT)                  |
   | - PostgreSQL / SQLite Persistence                             |
   | - Court-Admissible Audit Verification Engine                  |
   +---------------------------------------------------------------+
```

---

## 3. Technology Stack

- **Mobile Application**:
  - **Flutter 3.x / Dart 3.x**: Cross-platform Android-first client.
  - **Material 3 Design**: Strict government/forensic visual standard.
  - **Design System Palette**:
    - Classic Black (`#111111`) & Background (`#0D0D0D`)
    - Pure White (`#FFFFFF`)
    - Deep Brown (`#3E2723`)
    - Tactical Khaki (`#C3B091`)
    - Zero decorative clutter, zero neon, high contrast typography.
- **Cryptography & Algorithms**:
  - Pure Dart implementation of Sharma-Wu-Dalal CIEDE2000 ($\Delta E_{00}$)
  - Deterministic canonical JSON key-sorting serializer
  - SHA-256 cryptographic sealing & hash chaining
- **Backend API**:
  - **FastAPI / Python 3.14**: High-performance asynchronous API
  - **SQLAlchemy 2.0**: Relational ORM supporting SQLite and PostgreSQL
  - **PyJWT & Passlib**: Secure token authentication and RBAC
  - **Uvicorn**: ASGI web server

---

## 4. Color Science & CIEDE2000 Engine

Standard Euclidean RGB or HSV distances fail in legal forensics because human eye sensitivity varies across hues and saturations. NEXORA implements the rigorous CIE pipeline:

1. **sRGB Inverse Companding**:
   $$\text{Channel}_{lin} = \begin{cases} \frac{V}{12.92} & V \le 0.04045 \\ \left(\frac{V + 0.055}{1.055}\right)^{2.4} & V > 0.04045 \end{cases}$$
2. **CIE XYZ Transformation (D65 Standard Illuminant, $2^\circ$ Observer)**:
   $$X = 0.4124564 R_{lin} + 0.3575761 G_{lin} + 0.1804375 B_{lin}$$
   $$Y = 0.2126729 R_{lin} + 0.7151522 G_{lin} + 0.0721750 B_{lin}$$
   $$Z = 0.0193339 R_{lin} + 0.1191920 G_{lin} + 0.9503041 B_{lin}$$
3. **CIELAB Conversion ($L^*a^*b^*$)**:
   Maps XYZ values relative to D65 reference white $(X_n = 0.95047, Y_n = 1.00000, Z_n = 1.08883)$.
4. **CIEDE2000 Equation ($\Delta E_{00}$)**:
   Incorporates lightness ($S_L$), chroma ($S_C$), and hue ($S_H$) weighting functions along with the rotation factor ($R_T$) to correct blue-region ellipse orientations.
5. **Neutral Gray Patch Normalization**:
   Samples an $18\%$ neutral gray card in the camera view to estimate illuminant gains $(g_R, g_G, g_B)$ and eliminate yellow/blue color cast.
6. **Inconclusive Threshold**:
   A configurable threshold ($\Delta E_{00} > 2.0$) strictly marks the test as **`INCONCLUSIVE / MATRIX INTERFERENCE`**, preventing false positives.

---

## 5. Cryptographic Chain of Custody & Tamper Evident Sealing

### Canonical Evidence Seal Formula
To eliminate ambiguity, payloads are serialized using strict lexicographical key sorting:
$$\text{Evidence Hash} = \text{SHA-256}\left(\text{Canonical}(\text{RawImageHash}, \text{GPS Lat/Long/Acc}, \text{UTC Timestamp}, \text{OfficerBadgeId}, \text{CaseId})\right)$$

### Append-Only Hash Chaining
Every record is cryptographically linked to the preceding record:
$$\text{RecordHash}_n = \text{SHA-256}\left(\text{Canonical}(\text{RecordId}_n, \text{EvidenceHash}_n, \text{RecordHash}_{n-1}, \text{TimestampUtc}_n, \text{OfficerId}_n)\right)$$
If a bad actor attempts to change even one GPS coordinate or timestamp byte anywhere in history, the entire chain recalculation immediately fails with **`INTEGRITY FAILURE`**.

---

## 6. Dual-Portal Access (Officer RBAC & Citizen Watch)

| Feature / Capability | OFFICER | SUPERVISOR | ADMIN | CITIZEN WATCH |
| :--- | :---: | :---: | :---: | :---: |
| Authenticate with Badge ID & Passcode | Yes | Yes | Yes | No (Anonymous) |
| Execute New Field Test & Capture Image | Yes | No | Yes | No |
| View Own Assigned Case Records | Yes | Yes | Yes | No |
| View All Department Records | No | Yes | Yes | No |
| Verify Hash Chain Integrity | Yes | Yes | Yes | No |
| View System Security Audit Trail | No | Yes | Yes | No |
| Manage Authorized Reference Profiles | No | No | Yes | No |
| Submit Anonymous Community Tip | No | No | No | Yes |
| View Officer / Case Information | Yes | Yes | Yes | **NO (Zero Exposure)** |

---

## 7. Offline-First Resilience & Sync Queue

1. When offline (e.g. in cellular dead zones), records are committed to the local encrypted SQLite vault and flagged as **`PENDING_SYNC`**.
2. When connectivity is detected or restored, the background synchronization worker transmits the batch payload with unique **`X-Idempotency-Key`** headers.
3. The server recalculates and verifies the canonical SHA-256 hash. Upon verification, the server commits the record and returns an acknowledgement token.
4. The local record transitions to **`SYNCED`**. Original local evidence is retained in the vault.

---

## 8. SIH Judge 3–5 Minute Demonstration Flow

Evaluators can follow this step-by-step demonstration:

1. **Login & RBAC**:
   - Tap preset chip `OFFICER: 104` (Passcode: `Password@123`).
   - Tap **`AUTHENTICATE SESSION`**.
   - Note the government/forensic dashboard with KPI metrics, connectivity indicator (`ONLINE`), and statutory notice.
2. **New Field Test**:
   - Tap **`NEW FIELD TEST`**. Case ID is pre-filled (`CASE-2026-0891`), Reagent: `Marquis Reagent`.
   - Tap **`PROCEED TO DUAL-TARGET CAMERA CAPTURE`**.
3. **Camera & Multi-Frame Burst**:
   - Observe the dual-target viewfinder (Target A: Reaction Pouch, Target B: Reference Card).
   - Tap **`EXECUTE 5-FRAME FORENSIC CAPTURE`**.
   - Watch the multi-frame noise averaging sequence.
4. **Step-by-Step Analysis Progress**:
   - Review the 8-step chronological analysis pipeline (Image Capture $\to$ Reference Calibration $\to$ Normalization $\to$ LAB $\to$ CIEDE2000 $\to$ Reference Comparison $\to$ SHA-256 Evidence Seal).
5. **Presumptive Result & Statutory Notice**:
   - Inspect the Result Screen: Confirm it displays **`"PRESUMPTIVE RESULT"`** and **`"Possible matching reference profiles"`**.
   - Confirm it **never** says "Drug confirmed".
   - Confirm the prominent statutory disclaimer: *"Presumptive Field Screener Only — Confirmatory Lab Testing (GC-MS) Statutorily Mandated."*
   - Review ranked profiles (Similarity: $95.2\%$, $\Delta E_{00} = 0.52$).
   - Tap **`SAVE EVIDENCE`**.
6. **Offline Mode Demonstration**:
   - On Dashboard, tap the **`ONLINE`** indicator pill $\to$ shifts to **`OFFLINE`**.
   - Run another test; observe that it saves locally as **`PENDING_SYNC`**.
   - Tap **`OFFLINE`** pill $\to$ shifts to **`ONLINE`** $\to$ triggers auto-sync $\to$ status updates to **`SYNCED`**.
7. **Integrity & Tamper Demonstration**:
   - Tap **`VERIFY RECORD`** on Dashboard.
   - Observe local vault status: **`INTEGRITY VERIFIED`** (all nodes unbroken).
   - Tap **`RUN TAMPER DETECTION SIMULATION`**.
   - Watch the mathematical demonstration: altering 1 character in a historical copy triggers instant **`INTEGRITY FAILURE`** and pinpointed breach detection!
8. **Citizen Watch Portal**:
   - Log out $\to$ tap **`ACCESS CITIZEN WATCH`**.
   - Fill out an anonymous tip with optional location.
   - Tap **`TRANSMIT ANONYMOUS TIP SECURELY`**.
   - Receive anonymous receipt ID (e.g. `TIP-2026-98142`). No officer information is leaked.

---

## 9. Project Directory Structure

```
nexora/
├── README.md
├── pubspec.yaml
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── constants/
│   │   │   ├── api_endpoints.dart
│   │   │   ├── app_constants.dart
│   │   │   └── color_constants.dart
│   │   ├── theme/
│   │   │   └── forensic_theme.dart
│   │   ├── security/
│   │   │   ├── canonical_serializer.dart
│   │   │   ├── hash_service.dart
│   │   │   ├── hash_chain.dart
│   │   │   └── digital_seal.dart
│   │   ├── storage/
│   │   │   ├── database_helper.dart
│   │   │   └── encrypted_storage_service.dart
│   │   └── utils/
│   ├── models/
│   │   ├── evidence_record.dart
│   │   ├── reference_profile.dart
│   │   ├── audit_event.dart
│   │   ├── user_session.dart
│   │   └── citizen_tip.dart
│   ├── services/
│   │   ├── color_engine.dart
│   │   ├── camera_service.dart
│   │   ├── location_service.dart
│   │   ├── evidence_service.dart
│   │   ├── sync_service.dart
│   │   └── auth_service.dart
│   ├── features/
│   │   ├── authentication/
│   │   │   ├── splash_screen.dart
│   │   │   └── login_screen.dart
│   │   ├── dashboard/
│   │   │   └── officer_dashboard_screen.dart
│   │   ├── field_test/
│   │   │   ├── new_field_test_screen.dart
│   │   │   ├── camera_screen.dart
│   │   │   ├── analysis_progress_screen.dart
│   │   │   └── result_screen.dart
│   │   ├── evidence/
│   │   │   ├── evidence_vault_screen.dart
│   │   │   ├── evidence_detail_screen.dart
│   │   │   └── test_history_screen.dart
│   │   ├── map/
│   │   │   └── map_screen.dart
│   │   ├── verification/
│   │   │   ├── integrity_verification_screen.dart
│   │   │   └── audit_log_screen.dart
│   │   ├── citizen_watch/
│   │   │   ├── citizen_watch_screen.dart
│   │   │   ├── citizen_tip_submission_screen.dart
│   │   │   └── submission_confirmation_screen.dart
│   │   └── admin/
│   │       └── admin_reference_profiles_screen.dart
│   └── widgets/
│       ├── statutory_disclaimer_banner.dart
│       ├── forensic_metric_card.dart
│       ├── status_indicator_badge.dart
│       ├── similarity_progress_bar.dart
│       └── forensic_data_table.dart
├── android/
│   └── app/src/main/AndroidManifest.xml
├── test/
│   ├── pubspec.yaml
│   ├── color_engine_test.dart
│   ├── hash_test.dart
│   ├── storage_test.dart
│   └── sync_test.dart
└── backend/
    ├── requirements.txt
    ├── main.py
    ├── config.py
    ├── database.py
    ├── models.py
    ├── schemas.py
    ├── security.py
    ├── services.py
    ├── api_routes.py
    └── tests/
        └── test_backend_api.py
```

---

## 10. Setup and Installation

### Prerequisites
- **Python 3.10+** (tested on 3.14)
- **Dart SDK 3.3+** (or Flutter SDK)

### Backend Setup
```bash
cd nexora/backend
pip install -r requirements.txt
```

---

## 11. Running the System

### A. Starting the FastAPI Backend Server
```bash
cd nexora/backend
python main.py
```
*Server boots on `http://127.0.0.1:8000`. Interactive OpenAPI documentation available at `http://127.0.0.1:8000/docs`.*

### B. Running the Flutter Mobile Application
```bash
cd nexora
flutter run
```

---

## 12. Automated Test Suite Verification

NEXORA includes complete automated test coverage for both color science / cryptographic algorithms and the backend API.

### Running Dart Core & Color Engine Tests (22 Tests)
```bash
cd nexora/test
dart test color_engine_test.dart hash_test.dart storage_test.dart sync_test.dart
```
**Verification Output:**
```
00:00 +0: ColorEngine - CIE Transformations (RGB -> XYZ -> CIELAB) ... PASSED
00:00 +4: ColorEngine - CIEDE2000 Distance Calculation ... PASSED
00:00 +6: ColorEngine - Reference Card Normalization ... PASSED
00:00 +7: ColorEngine - Image Quality Gates ... PASSED
00:00 +10: ColorEngine - Threshold Gate (ΔE > 2.0 Inconclusive) ... PASSED
00:00 +11: Canonical Serialization & SHA-256 Sealing ... PASSED
00:00 +14: Avalanche Effect Verification ... PASSED
00:00 +18: Append-Only Hash Chain Continuity ... PASSED
00:00 +20: Tamper Detection Simulation (1-bit breach) ... PASSED
00:00 +22: All tests passed!
```

### Running Backend API & RBAC Pytest Suite (5 Tests)
```bash
cd nexora/backend
python -m pytest tests/test_backend_api.py -v
```
**Verification Output:**
```
tests/test_backend_api.py::test_health_check_returns_statutory_notice PASSED
tests/test_backend_api.py::test_officer_login_success_and_failure PASSED
tests/test_backend_api.py::test_rbac_profile_modification_denied_for_officer PASSED
tests/test_backend_api.py::test_evidence_ingestion_and_integrity_verification PASSED
tests/test_backend_api.py::test_anonymous_citizen_tip_submission PASSED
======================= 5 passed in 9.76s =======================
```

---

## 13. Limitations & Production Hardening

1. **Presumptive Spot Screening**: Color spot testing can only indicate presumptive classes and functional group reactions. Confirmatory laboratory testing (e.g. Gas Chromatography–Mass Spectrometry [GC-MS] or High-Performance Liquid Chromatography [HPLC]) remains legally mandated for criminal court proceedings.
2. **Camera Hardware Differences**: While neutral-gray card normalization dynamically corrects ambient white balance, severe camera lens distortions or dirty smartphone covers require visual inspection. The application's quality gate alerts officers when blur or illumination is insufficient.
3. **Local Encryption**: In production deployment, SQLite encryption keys should be delegated to hardware-backed Android Keystore StrongBox Keymaster chips.
