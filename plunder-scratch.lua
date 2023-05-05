local lib = require("./lib")
local plunder = require("./plunderlib")
local winapi = require('winapi')

USE_SERVER = false
USE_SERVER_INPUT = false

frameTimer = 0
SHOW_DEBUG = true

-- this is used externally to send information to this window
windowName = "untitled"

-- if there's multiple instances with same name, they can be used to distinguish them
instance = 0

function main()
	print("starting lua stuff")
	-- loop forever waiting for clients
	currentGame = "mario"
	print("rom: ", gameinfo.getromname())
	domainToCheck = "RDRAM"
	MARIO_LEVEL_CASTLE_LOBBY = 6
	currMem = {}
	local w1 = winapi.get_foreground_window()


	-- https://github.com/TASEmulators/BizHawk/issues/1141#issuecomment-410577001
	started = false
	-- huge hack, there's no way to pass in parameters to bizhawk commandline
	-- so we pass them through the httpgeturl =)
	if (started == false) then
		--if lua is loaded, dont rerun lua init
					--do things here that only need to be run once
		userdata.set("init", true) --init has been run once
		if USE_SERVER then
			print(comm.httpGetGetUrl())
			local g = comm.httpGetGetUrl()
			local query = lib.last(lib.split(g, "/"))
			local split = lib.split(query, "-")
			local game = split[1]
			windowName = split[2] or game
			if #split > 1 then instance = tonumber(split[2]) end
			-- currentGame = name -- TODO: maybe add info to game's name
			print("systemid: "..emu.getsystemid())
			print("windowName: "..windowName)
			plunder.setGame(game)
		end
	end

	while true do

		gui.clearGraphics()
		if USE_SERVER_INPUT then
			plunder.getServerInput(windowName)
		end

		if client.ispaused then
			emu.yield()
		else
			emu.frameadvance()
		end

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
			local value = newMem[key]
			local msg = currentGame.."/"..key..":"..value
			dbg = dbg..msg.."\n"
		end

		-- plunder.sendServerState(windowName, instance, newMem)

		if SHOW_DEBUG then
			gui.text(10, 10, dbg)
		end

		local x = newMem["posX"]
		local minX = -7500
		local maxX = 7500
		local pctX = lib.inverselerp(minX, maxX, x)

		local y = newMem["posY"]
		local minY = -1500
		local maxY = 1500
		local pctY = lib.inverselerp(minY, maxY, x)

		local z = newMem["posZ"]
		local minZ = -7500
		local maxZ = 7500
		local pctZ = lib.inverselerp(minZ, maxZ, z)

		local size = pctZ * 500
		local top = pctY * 600
		local left = pctX * 800


		w1:resize(top, left, size, size)


	end
end


main()