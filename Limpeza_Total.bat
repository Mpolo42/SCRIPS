@echo off
setlocal enabledelayedexpansion
title Limpador Avancado de Usuarios e Temporarios

:: ==============================
:: Preparacao do LOG (com data e hora)
:: ==============================
for /f "tokens=1-4 delims=/ " %%a in ('date /t') do (
    set dow=%%a
    set month=%%b
    set day=%%c
    set year=%%d
)
for /f "tokens=1-2 delims=: " %%a in ('time /t') do (
    set hh=%%a
    set mm=%%b
)
:: Remove caracteres inválidos de hora
set hh=%hh: =0%
set mm=%mm::=%

set LOG=%USERPROFILE%\Downloads\limpeza_%year%-%month%-%day%_%hh%-%mm%.txt

echo ============================================== >> %LOG%
echo EXECUCAO EM %date% %time% >> %LOG%
echo ============================================== >> %LOG%

:: ==============================
:: Calcula tamanho inicial do disco C:
:: ==============================
for /f %%a in ('powershell -command "(Get-Volume -DriveLetter C).SizeRemaining"') do set before=%%a

echo ============================================
echo  Limpando arquivos temporarios, navegadores e usuarios inativos
echo ============================================
echo.

:: Contadores de resumo
set count_users=0
set count_chrome=0
set count_edge=0
set count_firefox=0
set count_temp=0

:: ==============================
:: Limpeza TEMP do Windows
:: ==============================
echo Limpando C:\Windows\Temp ...
echo Limpando C:\Windows\Temp ... >> %LOG%
del /f /s /q C:\Windows\Temp\* 2>nul && set /a count_temp+=1
for /d %%i in (C:\Windows\Temp\*) do rd /s /q "%%i"

:: ==============================
:: Limpeza Prefetch
:: ==============================
echo Limpando C:\Windows\Prefetch ...
echo Limpando C:\Windows\Prefetch ... >> %LOG%
del /f /s /q C:\Windows\Prefetch\* 2>nul && set /a count_temp+=1
for /d %%i in (C:\Windows\Prefetch\*) do rd /s /q "%%i"

:: ==============================
:: Limpeza TEMP de todos usuarios
:: ==============================
echo Limpando arquivos temporarios de todos os usuarios ...
echo Limpando TEMP de todos os usuarios... >> %LOG%
for /d %%u in (C:\Users\*) do (
    if exist "%%u\AppData\Local\Temp" (
        echo Limpando: %%u\AppData\Local\Temp
        echo Limpando %%u\AppData\Local\Temp >> %LOG%
        del /f /s /q "%%u\AppData\Local\Temp\*" 2>nul && set /a count_temp+=1
        for /d %%i in ("%%u\AppData\Local\Temp\*") do rd /s /q "%%i"
    )
)

:: ==============================
:: Limpeza Google Chrome
:: ==============================
echo Limpando Google Chrome...
echo Limpando Google Chrome... >> %LOG%
for /d %%u in (C:\Users\*) do (
    if exist "%%u\AppData\Local\Google\Chrome\User Data\Default\Cache" (
        rd /s /q "%%u\AppData\Local\Google\Chrome\User Data\Default\Cache"
        set /a count_chrome+=1
    )
    if exist "%%u\AppData\Local\Google\Chrome\User Data\Default\Code Cache" (
        rd /s /q "%%u\AppData\Local\Google\Chrome\User Data\Default\Code Cache"
        set /a count_chrome+=1
    )
    if exist "%%u\AppData\Local\Google\Chrome\User Data\Default\GPUCache" (
        rd /s /q "%%u\AppData\Local\Google\Chrome\User Data\Default\GPUCache"
        set /a count_chrome+=1
    )
)

:: ==============================
:: Limpeza Microsoft Edge
:: ==============================
echo Limpando Microsoft Edge...
echo Limpando Microsoft Edge... >> %LOG%
for /d %%u in (C:\Users\*) do (
    if exist "%%u\AppData\Local\Microsoft\Edge\User Data\Default\Cache" (
        rd /s /q "%%u\AppData\Local\Microsoft\Edge\User Data\Default\Cache"
        set /a count_edge+=1
    )
    if exist "%%u\AppData\Local\Microsoft\Edge\User Data\Default\Code Cache" (
        rd /s /q "%%u\AppData\Local\Microsoft\Edge\User Data\Default\Code Cache"
        set /a count_edge+=1
    )
    if exist "%%u\AppData\Local\Microsoft\Edge\User Data\Default\GPUCache" (
        rd /s /q "%%u\AppData\Local\Microsoft\Edge\User Data\Default\GPUCache"
        set /a count_edge+=1
    )
)

:: ==============================
:: Limpeza Mozilla Firefox
:: ==============================
echo Limpando Mozilla Firefox...
echo Limpando Mozilla Firefox... >> %LOG%
for /d %%u in (C:\Users\*) do (
    for /d %%p in ("%%u\AppData\Roaming\Mozilla\Firefox\Profiles\*") do (
        if exist "%%p\cache2" (
            rd /s /q "%%p\cache2"
            set /a count_firefox+=1
        )
        if exist "%%p\cookies.sqlite" (
            del /f /q "%%p\cookies.sqlite"
            set /a count_firefox+=1
        )
        if exist "%%p\places.sqlite" (
            del /f /q "%%p\places.sqlite"
            set /a count_firefox+=1
        )
    )
)

:: ==============================
:: Identificacao de usuarios inativos > 180 dias
:: ==============================
echo.
echo Verificando usuarios inativos (mais de 180 dias)...
echo. >> %LOG%
echo Verificando usuarios inativos (mais de 180 dias)... >> %LOG%

set count=0

for /d %%u in (C:\Users\*) do (
    set username=%%~nxu

    :: Ignora Admin e Public
    if /i not "!username!"=="Administrador" if /i not "!username!"=="Public" (

        :: Verifica ultima modificacao da pasta do perfil
        for /f %%d in ('powershell -command "(Get-Date).AddDays(-180) -gt (Get-Item '%%u').LastWriteTime"') do set inactive=%%d

        if "!inactive!"=="True" (
            set /a count+=1
            set /a count_users+=1
            echo !count!. Usuario inativo: !username!
            echo Usuario inativo encontrado: !username! >> %LOG%

            rd /s /q "%%u"
            echo    -> Apagando pasta %%u >> %LOG%

            for /f "tokens=*" %%s in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" /s /v ProfileImagePath ^| find "%%u"') do (
                for %%k in (%%s) do reg delete "%%~dp0" /f >nul 2>&1
            )
            echo    -> Registro do perfil apagado >> %LOG%
        )
    )
)

if %count%==0 (
    echo Nenhum usuario inativo encontrado.
    echo Nenhum usuario inativo encontrado. >> %LOG%
)

:: ==============================
:: Calcula tamanho final e espaco liberado
:: ==============================

:: Pega o valor final
for /f %%a in ('powershell -command "(Get-Volume -DriveLetter C).SizeRemaining"') do set after=%%a

:: Usa PowerShell para fazer o calculo (set /a tem limite de 32-bits e falha)
:: O PowerShell vai retornar 3 valores (bytes, MB, GB) separados por espaco
for /f "tokens=1,2,3" %%a in ('powershell -command "$freed = [decimal]%after% - [decimal]%before%; $freedMB = [Math]::Round($freed / 1MB, 0); $freedGB = [Math]::Round($freed / 1GB, 2); Write-Host \"$freed $freedMB $freedGB\""') do (
    set freed=%%a
    set freedMB=%%b
    set freedGB=%%c
)

:: ==============================
:: Resumo final
:: ==============================
echo. 
echo ======= RESUMO DA LIMPEZA =======
echo Usuarios removidos: %count_users%
echo Pastas TEMP limpas: %count_temp%
echo Chrome limpo: %count_chrome% vezes
echo Edge limpo: %count_edge% vezes
echo Firefox limpo: %count_firefox% vezes
echo Espaco liberado: %freed% bytes (%freedMB% MB / %freedGB% GB)
echo =================================
echo.

>> %LOG% echo ======= RESUMO DA LIMPEZA =======
>> %LOG% echo Usuarios removidos: %count_users%
>> %LOG% echo Pastas TEMP limpas: %count_temp%
>> %LOG% echo Chrome limpo: %count_chrome% vezes
>> %LOG% echo Edge limpo: %count_edge% vezes
>> %LOG% echo Firefox limpo: %count_firefox% vezes
>> %LOG% echo Espaco liberado: %freed% bytes (%freedMB% MB / %freedGB% GB)
>> %LOG% echo =================================
>> %LOG% echo.

echo [OK] Limpeza concluida!
pause
