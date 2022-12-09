local lib = require("./lib")
local plunder = require("./plunderlib")
local newdecoder = require 'decoder'
local decodeJson = newdecoder()

USE_SERVER = true
USE_SERVER_INPUT = true
ROM_PATH = "..\\roms\\"
ROMS = {
	-- path to roms
	zelda = ROM_PATH.."zelda.n64",
	mario = ROM_PATH.."mario.n64",
	tonyhawk = ROM_PATH.."thps2.n64",
}

frameTimer = 0
showScreen = true

-- this is used externally to send information to this window
windowName = "untitled"

-- if there's multiple instances with same name, they can be used to distinguish them
instance = 0

function main()
	print("starting lua stuff")
	-- loop forever waiting for clients
	currentGame = "none"
	print("rom: ", gameinfo.getromname())
	domainToCheck = "RDRAM"
	MARIO_LEVEL_CASTLE_LOBBY = 6
	currMem = {}


	-- https://github.com/TASEmulators/BizHawk/issues/1141#issuecomment-410577001
	started = false

	-- huge hack, there's no way to pass in parameters to bizhawk commandline
	-- so we pass them through the httpgeturl =)
	if (started == false) then
		--if lua is loaded, dont rerun lua init
					--do things here that only need to be run once
		userdata.set("init", true) --init has been run once
		if USE_SERVER then
			local g = comm.httpGetGetUrl()
			local query = lib.last(lib.split(g, "/"))
			local split = lib.split(query, "#")
			local game = split[1]
			windowName = game
			if #split > 1 then instance = split[2] end
			-- currentGame = name -- TODO: maybe add info to game's name
			winapi.get_foreground_window():set_text("bizhawk:"..comm.httpGetGetUrl())
			print("systemid: "..emu.getsystemid())
			plunder.setGame(game)
		end
	end

	while true do
		-- plunder.getServerInput(windowName, instance)

		emu.frameadvance()
	end
	while true do

		if frameTimer >= 0 then
			frameTimer = frameTimer + 1
		end
		if frameTimer > 60 then
			frameTimer = 0
		end

		local newMem = plunder.readMemory(currentGame)
		-- build log and send to server
		local dbg = ""
		for i, key in ipairs(lib.get_keys(newMem)) do
			local msg = currentGame.."/"..key..":"..value
			if mem[key]["curr"] ~= value then
				mem[key]["curr"] = math.abs(value) < 0.001 and 0 or value
				plunder.sendServerMessage(msg)
			end
			dbg = dbg..msg.."\n"
		end

		if showScreen then
			gui.clearGraphics()
			gui.text(10, 10, dbg)
		end

		if currentGame == "mario" then
			local joypad = joypad.get(1)
			if joypad["A"] then
				-- savestate.saveslot(1)
				-- setGame("zelda")
				frameTimer = 0
			end

			if frameTimer > 60 then
				-- savestate.saveslot(1)
				plunder.setGame("zelda")
				frameTimer = 0
			end
		elseif currentGame == "zelda" then
			if frameTimer > 60 then
				plunder.setGame("mario")
				frameTimer = 0
			end
		end
	end
end


main()