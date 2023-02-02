@REM start /B python %PLUNDER_HOME%\scripts\plunder_server.py
@REM start /B python %PLUNDER_HOME%\scripts\plunder_client.py

start %PLUNDER_HOME%/scripts/bizhawk_noserver.bat mario
ping 192.0.2.1 -n 1 -w 5000 > nul
start %PLUNDER_HOME%/scripts/bizhawk_noserver.bat mario-2
ping 192.0.2.1 -n 1 -w 5000 > nul
start %PLUNDER_HOME%/scripts/bizhawk_noserver.bat zelda

@REM start python %PLUNDER_HOME%\scripts\mmf-server.py