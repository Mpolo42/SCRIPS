@echo off
chcp 65001 >nul
echo ============================================
echo  Verificando TPM 2.0, Secure Boot e Certificado 2026
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

:: Verifica a CA 2023 
for /f "tokens=*" %%a in ('powershell -command "([System.Text.Encoding]::ASCII.GetString((Get-SecureBootUEFI db).bytes) -match 'Windows UEFI CA 2023')"') do set CA2023=%%a

if /i "%CA2023%"=="True" (
    echo [OK] Windows UEFI CA 2023 Detectada
) else (
    echo [AVISO] Windows UEFI CA 2023 nao encontrada - Requer atualizacao de DBX/DB
)

echo.
pause