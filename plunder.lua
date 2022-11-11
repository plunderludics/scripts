lib = require("./lib")
local newdecoder = require 'decoder'
local decode = newdecoder()

USE_SERVER = true
USE_SERVER_INPUT = true
ROM_PATH = "..\\roms\\"
ROMS = {
	-- path to roms
	zelda = ROM_PATH.."zelda.n64",
	mario = ROM_PATH.."mario.n64",
	-- mario = "mario.nes",
	-- zelda = "zelda.nes",
}

server_lastInput = {}
server_input = {}
frameTimer = 0


function main()
	print("starting lua stuff")
	-- loop forever waiting for clients
	currentGame = "none"
	print("rom: ", gameinfo.getromname())
	domainToCheck = "RDRAM"
	MARIO_LEVEL_CASTLE_LOBBY = 6

	MEM = {
		mario = {
			coins = {byte = 0x33B219, size = 2},
			stars = {byte = 0x33B21A, size = 2}, -- writing doesn't do anything

			level = {byte = 0x33B249, size = 1}, -- writing doesn't do anything
			status = {byte = 0x33B172, size = 2},
			action = {byte = 0x33B17C, size = 4},
			health = {byte = 0x33B21E, size = 1},

			-- Y is the up axis
			posX = {byte = 0x33B1AC, size = 4, kind="FLOAT"},
			posY = {byte = 0x33B1B0, size = 4, kind="FLOAT"},
			posZ = {byte = 0x33B1B4, size = 4, kind="FLOAT"},

			offY = {byte = 0x33B220, size = 4, kind="FLOAT"},

			vel = {byte = 0x33B1C4, size=4, kind="FLOAT"},
			velX = {byte = 0x33B1B8, size=4, kind="FLOAT"},
			velY = {byte = 0x33B1BC, size=4, kind="FLOAT"},
			velZ = {byte = 0x33B1C0, size=4, kind="FLOAT"},

			camX = {byte = 0x33C6A4, size=4, kind="FLOAT"},
			camY = {byte = 0x33C6A8, size=4, kind="FLOAT"},
			camZ = {byte = 0x33C6AC, size=4, kind="FLOAT"},

			phase = {byte = 0x33B17C, size = 4}, -- writing doesn't do anything
			cycle = {byte = 0x33B18A, size = 2}, -- writing doesn't do anything
		},
		zelda = {
			rupees = {byte = 0x10C78A, size = 1},

			velY = {byte = 0x576958 , size=4, kind="FLOAT"},
			vel = {byte = 0x31D960 , size=4, kind="FLOAT"},
		},
	}

	-- https://github.com/TASEmulators/BizHawk/issues/1141#issuecomment-410577001
	started = false
	-- if (userdata.containskey("init")) then
	-- 	started = userdata.get("init")
	-- 	console.log("userdata retrieved")
	-- else
	-- 	userdata.set("init", false)
	-- 	started = userdata.get("init")
	-- 	console.log("userdata not set")
	-- end
	-- if started then
	-- 	Stringstarted = "true";
	-- else
	-- 	Stringstarted = "false";
	-- end
	-- console.log("Started?: " .. Stringstarted)

	if (started == false) then
		--if lua is loaded, dont rerun lua init
					--do things here that only need to be run once
		userdata.set("init", true) --init has been run once
		if USE_SERVER then
			local g = comm.httpGetGetUrl()
			local name = lib.last(lib.split(g, "/"))
			-- currentGame = name -- TODO: maybe add info to game's name
			print("systemid: "..emu.getsystemid())
			setGame(name)
		end
	end

	-- function cleanup()
	-- 	userdata.set("init", false)
	-- end

	-- event.onexit(cleanup)

	while true do
		getServerInput(currentGame)

		emu.frameadvance()

		if frameTimer >= 0 then
			frameTimer = frameTimer + 1
		end
		if frameTimer > 60 then
			frameTimer = 0
		end

		local mem = MEM[currentGame]
		local dbg = ""
		if mem == nil then
			print("no memory map for "..currentGame)
			break
		else
			keys = lib.get_keys(mem)
			table.sort(keys)
			for i, key in ipairs(keys) do
				address = mem[key]
				local value = getValue(address)
				local msg = currentGame.."/"..key..":"..value
				if mem[key]["curr"] ~= value then
					mem[key]["curr"] = math.abs(value) < 0.001 and 0 or value
					sendServerMessage(msg)
				end
				dbg = dbg..msg.."\n"
			end
		end

		gui.clearGraphics()
		gui.text(10, 10, dbg)

		if currentGame == "mario" then
			local joypad = joypad.get(1)
			if joypad["A"] then
				-- savestate.saveslot(1)
				-- setGame("zelda")
				frameTimer = 0
			end

			if frameTimer > 60 then
				-- savestate.saveslot(1)
				setGame("zelda")
				frameTimer = 0
			end
		elseif currentGame == "zelda" then
			if frameTimer > 60 then
				setGame("mario")
				frameTimer = 0
			end
		end
	end
end

function setGame(gameName)
	if currentGame ~= gameName then
		currentGame = gameName
		rom = ROMS[currentGame]

		print("loading game: "..gameName.." from "..rom)
		client.openrom(rom)
	end

	-- savestate.loadslot(1)
	-- print("loaded slot 1")
	-- domainToCheck = memoryForConsole(emu.getsystemid())
	print("loaded!")
end

function sendServerMessage(msg)
	if not USE_SERVER then return end
	comm.socketServerSend(msg)
end

function getServerInput(name)
	if not USE_SERVER then return end
	if not USE_SERVER_INPUT then return end
	resp = comm.httpGet(comm.httpGetGetUrl())
	if resp == nil then return end

	server_input = decode(resp)[name]
	if server_input ~= nil then

		local x = server_input["x"]
		local y = server_input["y"]
		joypad.setanalog({
			['X Axis'] = x and tostring(x * 127/5) or '',
			['Y Axis'] = y and tostring(y * 127/5) or '',
		}, 1)

		local a = server_input["a"] or 0
		local b = server_input["b"] or 0
		local z = server_input["z"] or 0
		joypad.set({
			['A'] = a ~= 0,
			['B'] = b ~= 0,
			['Z'] = z ~= 0,
		}, 1)

		local slot = math.floor(server_input["save"] or 0)
		if slot > 0 and slot ~= math.floor(server_lastInput["save"] or 0) then
			-- savestate.saveslot(slot)
		end

		slot = math.floor(server_input["load"] or 0)
		if slot > 0 and slot ~= math.floor(server_lastInput["load"] or 0) then
			-- savestate.loadslot(slot)
		end

		server_lastInput = server_input
	end
end


function getValue(address, base)
	local byte = address["byte"]
	local size = address["size"]
	local kind = address["kind"] or "INT"
	local base = base or 256

	local acc = 0
	if kind == "FLOAT" then
		acc = memory.readfloat(byte, true, domainToCheck)
	else
		local mult = 1
		for i = 1, size do
			local read = memory.readbyte(byte, domainToCheck)
			acc = acc + (read * mult)
			mult = mult * base
		end
	end

	return acc
end

function setValue(address, value, base)
	local byte = address["byte"]
	local size = address["size"]
	local kind = address["kind"] or "INT"
	local base = base or 256

	if kind == "FLOAT" then
		memory.writefloat(byte, value, true, domainToCheck)
	else
		-- write biggest byte last
		for i = 1, size do
			byte_value = math.floor(value/(base^i))%base;
			memory.writebyte(byte, byte_value, domainToCheck)
		end
	end
end

function memoryForConsole(whichConsole)
	if whichConsole == "GEN" then
		return "68K RAM"
	end

	if whichConsole == "GB" then
		return "CartRAM"
	end

	if whichConsole == "NES" then
		return "WRAM"
	end

	if whichConsole == "SMS" then
		return "Main RAM"
	end

	if whichConsole == "GG" then
		return "Main RAM"
	end

	if whichConsole == "SAT" then
		return "Work Ram High"
	end

	if whichConsole == "GBA" then
		return "IWRAM"
	end

	if whichConsole == "NULL" then
		return "RDRAM"
	end

	-- if whichConsole == "N64" then
		-- return "RDRAM"
	-- end

	return memory.getcurrentmemorydomain()
end

rom_path = "D:\\roms\\SNES\\Super Mario World (U) [!].smc";
if userdata.get("last_openrom_path") == rom_path then
	userdata.remove("last_openrom_path");
else
	userdata.set("last_openrom_path", rom_path);
	client.openrom(rom_path);
end
main()