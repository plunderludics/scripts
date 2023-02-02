start python %PLUNDER_HOME%\scripts\mmf-server.py
ping 192.0.2.1 -n 1 -w 3000 > nul
start %PLUNDER_HOME%/scripts/bizhawk_noserver.bat formulaone
ping 192.0.2.1 -n 1 -w 3000 > nul
start %PLUNDER_HOME%/scripts/bizhawk_noserver.bat mariokart
ping 192.0.2.1 -n 1 -w 3000 > nul
start %PLUNDER_HOME%/scripts/bizhawk_noserver.bat wipeout
ping 192.0.2.1 -n 1 -w 3000 > nul
start %PLUNDER_HOME%/scripts/bizhawk_noserver.bat mario

