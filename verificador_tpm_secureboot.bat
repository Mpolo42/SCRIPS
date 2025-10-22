@echo off
chcp 65001 >nul
echo ============================================
echo  Verificando TPM 2.0 e Secure Boot
echo ============================================
echo.

:: Verifica TPM 2.0
for /f "tokens=*" %%i in ('powershell -command "(Get-WmiObject -Namespace 'Root\CIMv2\Security\MicrosoftTpm' -Class Win32_Tpm).SpecVersion"') do set TPM=%%i

if not defined TPM (
    echo [FALHA] TPM nao encontrado
) else (
    echo TPM detectado: %TPM%
    echo %TPM% | find "2.0" >nul
    if %errorlevel%==0 (
        echo [OK] TPM 2.0 Ativo
    ) else (
        echo [FALHA] Versao TPM diferente de 2.0
    )
)

:: Verifica Secure Boot
for /f "tokens=*" %%i in ('powershell -command "Confirm-SecureBootUEFI"') do set SECUREBOOT=%%i

if /i "%SECUREBOOT%"=="True" (
    echo [OK] Secure Boot Ativo
) else (
    echo [FALHA] Secure Boot Desativado ou Nao Suportado
)

echo.
pause