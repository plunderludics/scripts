local lib = require("./lib/lib")
local plunder = require("./lib/plunder")

plunder.USE_SERVER = true
plunder.USE_SERVER_INPUT = true

frameTimer = 0
SHOW_DEBUG = true

-- this is used externally to send information to this window
windowName = "untitled"

-- if there's multiple instances with same name, they can be used to distinguish them
instance = 0

function main()
	print("starting lua stuff")
	-- loop forever waiting for clients
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
		print(comm.httpGetGetUrl())
		local g = comm.httpGetGetUrl()
		local query = lib.last(lib.split(g, "/"))
		local split = lib.split(query, "_")
		local sample = split[1]
		windowName = split[2] or game
		if #split > 1 then instance = tonumber(split[2]) end
		print("systemid: "..emu.getsystemid())
		print("sample: "..sample)
		print("windowName: "..windowName)
		plunder.runSample(sample)
	end

	while true do
		gui.clearGraphics()
		plunder.getServerInput(windowName)

		if client.ispaused then
			emu.yield()
		else
			emu.frameadvance()
		end

	-- end
	-- while true do

		if frameTimer >= 0 then
			frameTimer = frameTimer + 1
		end
		if frameTimer > 60 then
			frameTimer = 0
		end

		local newMem = plunder.readMemory()


		plunder.sendServerState(windowName, instance, newMem)

		-- build log and send to server
		-- local dbg = ""
		-- for i, key in ipairs(lib.get_keys(newMem)) do
		-- 	local msg = key..":"..value
		-- 	if mem[key]["curr"] ~= value then
		-- 		mem[key]["curr"] = math.abs(value) < 0.001 and 0 or value
		-- 	end
		-- 	dbg = dbg..msg.."\n"
		-- end

		if SHOW_DEBUG then
			gui.text(10, 10, dbg)
		end
	end
end


main()