@echo off
:: Habilitar o serviço Windows Time
echo Ativando o serviço Windows Time...
sc config w32time start= auto
net start w32time

:: Sincronizar com o servidor NTP
echo Configurando o servidor de tempo...
w32tm /config /manualpeerlist:"pool.ntp.org" /syncfromflags:manual /reliable:YES /update

:: Forçar a sincronização
echo Sincronizando com o servidor de tempo...
w32tm /resync

:: Mostrar a data e hora atualizadas
echo Data e hora atualizadas:
date /t
time /t

pause