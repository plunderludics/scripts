pushd %PLUNDER_HOME%
set txpath=%cd%\texture\biz
start /wait powershell -Command "(gc .\scripts\tonytony-thps2.ini) -replace 'TEXTURE_PATH', \"${pwd}\textures\biz\".replace('\', '/') | Out-File .\scripts\tonytony-thps2-mod.ini"
start /wait powershell -Command "(gc .\scripts\tonytony-mario.ini) -replace 'TEXTURE_PATH', \"${pwd}\textures\biz\".replace('\', '/') | Out-File .\scripts\tonytony-mario-mod.ini"
sleep 2
start /b .\BizHawk-2.8-win-x64\EmuHawk.exe \roms\thps2.z64 --lua="./scripts/tonytony-thps2.lua" --config="./scripts/tonytony-thps2-mod.ini"
start /b .\BizHawk-2.8-win-x64\EmuHawk.exe .\roms\mario.z64 --config="./scripts/tonytony-mario-mod.ini"
start /b .\tonytony-build\plunity.exe
popd