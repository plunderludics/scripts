local lib = require("./lib")
local plunder = {}

local json = require "json"

local newdecoder = require 'decoder'
local decodeJson = newdecoder()
local currentGame = "none"

function im(emu, osc)
	return { emu=emu, osc=osc}
end

INPUTS_MAPS = {
	{ emu="A", osc="a" },
	{ emu="B", osc="b" },
	{ emu="Z", osc="z" },
	{ emu="□", osc="square" },
	{ emu="△", osc="triangle" },
	{ emu="X", osc="X" },
	-- TODO: map all emulators ever
}

plunder.USE_SERVER = true
plunder.USE_SERVER_INPUT = true
LOG = true
SAMPLE_PATH = "..\\samples\\"
ROM_PATH_FILENAME = "rompath.txt"
SAVE_FILENAME = "save.State"
ROM_PATH = "..\\roms\\"
ROMS = {
	-- path to roms
	zelda = ROM_PATH.."zelda-mm.n64",
	mario = ROM_PATH.."mario.n64",
	tonyhawk = ROM_PATH.."thps2.n64",
}
FILE_SAVE_SLOT = 10


function log(str)
	if not LOG then return end
	print(str)
end

-- TODO: integrate with script hawk
plunder.MEM = {
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

		velY = {byte = 0x3FFE18	 , size=4, kind="FLOAT"},
		vel = {byte = 0x31D960 , size=4, kind="FLOAT"},
	},
	thps2 = {
			menu = {byte = 0x0E8124, size=4},
			ingame = {byte = 0x101E24, size=4}, -- = 48 in menu, 420 in game
	},
	teneighty = {
			character = {byte=0x020290, size=4},
			-- board = {byte=0x2C9A0C, size=4},
	},

	-- todo: make these come from files in the sample
}

function plunder.runSample(sampleName)
	-- TODO: add osc addresses to sample
	print ("[sample] loading: ".. sampleName)
	-- a sample folder contains a .txt file called rompath.txt which contents are the rom path
	local folderPath = SAMPLE_PATH..sampleName.."\\"
	local rompathfile = folderPath..ROM_PATH_FILENAME
	local savepathfile = folderPath..SAVE_FILENAME
  if not lib.file_exists(rompathfile) then
		print("ERROR: rompath file does not exist. "..rompathfile)
		return
	end
  local lines = {}
  local rompath = lib.lines_from(rompathfile)[1]
	print ("[sample] rom path: ".. rompath)

	local wasPaused = client.ispause
	if wasPaused then
		client.unpause()
	end

	local nextGame = lib.split(sampleName, "-")[1]
	if currentGame ~= nextGame then
		client.openrom(rompath)
		currentGame = nextGame
	end

  if lib.file_exists(savepathfile) then
		savestate.load(savepathfile)
		savestate.save(FILE_SAVE_SLOT)
	else
		print("WARNING: savepath file does not exist. "..savepathfile)
	end

	if wasPaused then
		client.pause()
	end
end

function plunder.setGame(gameName)
	if currentGame ~= gameName then
		currentGame = gameName
		print(currentGame)
		if ROMS[currentGame] == nil then
			ROMS[currentGame] = ROM_PATH..gameName..".z64"
		end
		rom = ROMS[currentGame]

		print("loading game: "..gameName.." from "..rom)
		client.openrom(rom)
	end

	-- savestate.loadslot(1)
	-- print("loaded slot 1")
	-- domainToCheck = memoryForConsole(emu.getsystemid())
	print("loaded!")
end

function plunder.sendServerMessage(msg)
	if not plunder.USE_SERVER then return end
	comm.socketServerSend(msg)
end

function plunder.sendServerState(game, instance, state)
	if not plunder.USE_SERVER then return end
	instance = instance or 0
	local fill = ""
	for i = 1,1000,1 do
		fill = fill.." "
	end
	local s = json.encode(state)..fill
	local ext = instance > 0 and "-"..instance or ""
	-- print("writing to "..windowName..ext.."_state :"..s)
	comm.mmfWrite(windowName..ext.."_state", s)
end

function plunder.readMemory()
	local game = currentGame
	local newMem = {}

	local addresses = plunder.MEM[game]
	if addresses == nil then
		print("no memory map for "..game)
		plunder.MEM[game] = {}
	else
		keys = lib.get_keys(addresses)
		table.sort(keys)
		for i, key in ipairs(keys) do
			address = addresses[key]
			local value = plunder.getValue(address)
			newMem[key] = value
		end
	end

	return newMem
end

serverInputLast = {}
serverInput = {}
MAX_ATTEMPTS = 1000
function plunder.getServerInput(windowName, instance)
	-- print("getting input")
	instance = instance or 0
	local ext = instance > 0 and "-"..instance or ""
	if not plunder.USE_SERVER then return end
	if not plunder.USE_SERVER_INPUT then return end
	resp = comm.mmfRead(windowName..ext.."_in", 1000)
	local i = 0
	while resp == nil or resp == "" and i < MAX_ATTEMPTS do
		resp = comm.mmfRead(windowName..ext.."_in", 1000)
		i = i + 1
	end

	if i == MAX_ATTEMPTS then
		print("error: TOO MANY ATTEMPTS TO READ")
		return
	end

	serverInput = json.decode(resp)
	if serverInput ~= nil then

		local x = serverInput["x-axis"]
		local y = serverInput["y-axis"]
		if y then
			-- print("y  :"..y.."="..tostring(y * 127/5).."\n")
		end

		joypad.setanalog({
			['X Axis'] = x and tostring(math.floor(x * 127/5)) or '',
			['Y Axis'] = y and tostring(math.floor(y * 127/5)) or '',
		}, 1)

		local b = serverInput["b"] or 0
		local z = serverInput["z"] or 0

		for i, m in pairs(INPUTS_MAPS) do
			local s = serverInput[m.osc] or 0
			if serverInputLast[m.osc] ~= a then
				joypad.set({
					[m.emu] = s > 0,
				}, 1)
			end
		end

		-- TODO: add abiity to write to memory directly

		local slot = math.floor(serverInput["save"] or 0)
		if slot > 0 and slot ~= math.floor(serverInputLast["save"] or 0) then
			savestate.saveslot(slot)
		end

		local volume = serverInput["volume"] or -1
		if (serverInputLast["volume"] or -1) ~= volume and volume >= 0 then
			client.SetVolume(volume)
		end

		slot = math.floor(serverInput["load"] or 0)
		if slot > 0 and slot ~= math.floor(serverInputLast["load"] or 0) then
			savestate.loadslot(slot)
		end

		local sample = serverInput["sample"] or false

		if serverInputLast["sample"] ~= sample and sample and sample ~= -1 then
			plunder.runSample(sample)
		end

		local pause = serverInput["pause"] or 0
		if (serverInputLast["pause"] or 0) ~= pause and pause > 0 then
			print("pausing")
			client.pause()
		end


		local unpause = serverInput["unpause"] or 0
		if (serverInputLast["unpause"] or 0) ~= unpause and unpause > 0 then
			print("unpausing")
			client.unpause()
		end

		serverInputLast = serverInput
	else
		print("no server input")
	end
end

function plunder.getValue(address, base, domain)
	local byte = address["byte"]
	local size = address["size"]
	local kind = address["kind"] or "INT"
	local base = base or 256
    local domain = domain or "RDRAM"

	local acc = 0
	if kind == "FLOAT" then
		acc = memory.readfloat(byte, true, domain)
	else
		local mult = 1
		for i = 1, size do
            local b = byte + size - i
			local read = memory.readbyte(b, domain)
			acc = acc + (read * mult)
			mult = mult * base
		end
	end

	return acc
end

function plunder.setValue(address, value, base, domain)
	local byte = address["byte"]
	local size = address["size"]
	local kind = address["kind"] or "INT"
	local base = base or 256
    local domain = domain or "RDRAM"

	if kind == "FLOAT" then
		memory.writefloat(byte, value, true, domainToCheck)
	else
		-- write biggest byte last
		for i = 1, size do
			byte_value = math.floor(value/(base^i))%base;
			memory.writebyte(byte + i - 1, byte_value, domainToCheck)
		end
	end
end

function plunder.memoryForConsole(whichConsole)
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


return plunder