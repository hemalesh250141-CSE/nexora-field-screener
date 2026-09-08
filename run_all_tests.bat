@echo off
echo ===================================================
echo 1. RUNNING NEXORA DART CORE & FORENSIC TESTS
echo ===================================================
cd test
call "C:\Users\Hemalesh\dart-sdk\dart-sdk\bin\dart.exe" test color_engine_test.dart hash_test.dart storage_test.dart sync_test.dart
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Dart core tests failed!
    exit /b %ERRORLEVEL%
)

echo.
echo ===================================================
echo 2. RUNNING NEXORA FASTAPI BACKEND AND RBAC PYTESTS
echo ===================================================
cd ..\backend
call python -m pytest tests/test_backend_api.py -v
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Backend tests failed!
    exit /b %ERRORLEVEL%
)

echo.
echo ===================================================
echo ALL 27 FORENSIC SYSTEM TESTS PASSED SUCCESSFULLY!
echo ===================================================
pause
