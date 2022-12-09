local lib = require("./lib")
local plunder = require("./plunderlib")

function main()
	print("starting lua...")
	-- loop forever waiting for clients
	currentGame = "thps2"
	print("rom: ", gameinfo.getromname())
	currMem = {}
	lastjoypad = {
    ["A"] = false
  }
  local pressedA = false

  while true do
		plunder.getServerInput(windowName, instance)

    joypad.set({
      ['Start'] = 0
    }, 1)

		local newMem = plunder.readMemory(currentGame)
    currMem = newMem
    local menu = currMem["menu"]
    local ingame = currMem["ingame"] == 420
    local j = joypad.get(1)
    -- gui.clearGraphics()
    -- gui.text(10, 10, menu.." "..tostring(j["A"]).." "..tostring(lastjoypad and lastjoypad["A"] or nil).."\ningame: "..tostring(ingame))
    if menu == 14 then
			if lastjoypad and not j["A"] and lastjoypad["A"] then
        lastjoypad = nil
        savestate.loadslot(5)
      end
      lastjoypad = joypad.get(1)
    elseif not ingame then
      if lastjoypad and not j["A"] and lastjoypad["A"] then
        savestate.loadslot(1)
      end
      lastjoypad = joypad.get(1)
      joypad.set({
        ['A'] = 0,
        ['B'] = 0,
        ['Start'] = z ~= 0,
      }, 1)
    else
      lastjoypad = nil
    end



		emu.frameadvance()

  end
end

main()