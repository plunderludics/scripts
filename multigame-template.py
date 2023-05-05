# https://github.com/Ashafix/PyEmuHawk/blob/master/PyEmuhawk.py

import mmap
import sys
import json

MMF_SIZE = 1000

# total arguments
n = len(sys.argv)

emulator_input = {}

game_states = {}

games_mmf  = {}

# get arguments passed in command line
gamelist = ["mario", "zelda", "mario-2"]

def main():
    # TODO: REPLACE CODE HERE TO INTERACT BETWEEN MULTIPLE GAMES
    # what this one is doing is checking if the speed in a game named zelda (when running from)

    if game_states["zelda"].get("velY", 0) > 0:
        emulator_input["mario-2"]["a"] = False
        emulator_input["mario"]["a"] = True
    else:
        emulator_input["mario-2"]["a"] = True
        emulator_input["mario"]["a"] = False


# get gamelist from command line
for i in range(1, len(sys.argv)):
    arg = sys.argv[i]
    print("arg " + arg)
    gamelist.append(arg)

for game in gamelist:
    game_states[game] = {}
    games_mmf[game] = mmap.mmap(-1, MMF_SIZE, game + "_in")
    emulator_input[game] = {}

c = 0
while True:
    # read game state from file
    for game in game_states:
        with mmap.mmap(-1, MMF_SIZE, game+"_state", mmap.ACCESS_READ) as mm:
            try:
                b = mm.read(MMF_SIZE)
                s = b.decode("utf-8").replace("\x00", "").strip()
                if len(s) == 0:
                    continue
                state = json.loads(s)
                game_states[game] = state
            except:
                print("something went wrong...")

    main()


    # write emulator input to file
    for game in emulator_input:
            # write emulator input to file
            mm = games_mmf[game]
            i = json.dumps(emulator_input[game])
            b = bytes(i, "utf-8")

            mm.seek(0)
            # mm.write(bytes([b"\x00"]*MMF_SIZE))
            # mm.seek(0)
            mm.write(b)
            mm.flush()

print("Closing resources")
mm.close()
