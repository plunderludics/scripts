# https://github.com/Ashafix/PyEmuHawk/blob/master/PyEmuhawk.py

import mmap
import sys
import json
import threading
import time

from pythonosc import udp_client
from pythonosc.dispatcher import Dispatcher
from pythonosc import osc_server

SOCKET_PORT = 6969
HTTP_PORT = 9876
OSC_SERVER_PORT = 4199
OSC_INITIAL_PORT = 4200
OSC_PORTS = 4
OSC_IPS = [
    "127.0.0.1"
]
LOCAL_IP = "127.0.0.1"

osc_input = {
    "test": "10"
}

MMF_SIZE = 1000

# total arguments
n = len(sys.argv)

emulator_input = {}

window_states = {}

emulators_mmf  = {}

# get arguments passed in command line
window_names = []

print("Creating OSC server")
def write_emu_input(game):
    mm = emulators_mmf[game]
    i = json.dumps(emulator_input[game])
    b = bytes(i, "utf-8")
    mm.seek(0)
    # mm.write(bytes([b"\x00"]*(MMF_SIZE)))
    # mm.seek(0)
    mm.write(b)
    mm.flush()

def emu_handler(address, *args):
    sub = address.split('/')
    game = sub[2]
    state = sub[3]
    value = args[0]
    print("OSC received: ", address, " | setting ", game, "-", state, "to ", value)
    emulator_input[game][state] = value
    # write emulator input to file
    write_emu_input(game)


dispatcher = Dispatcher()
dispatcher.map("/emu/*", emu_handler)
oscServer = osc_server.ThreadingOSCUDPServer((LOCAL_IP, OSC_SERVER_PORT), dispatcher)
oscServer_thread = threading.Thread(target=oscServer.serve_forever)
oscServer_thread.start()

osc_clients = []
for i in range(0, OSC_PORTS):
    port = OSC_INITIAL_PORT + i
    for ip in OSC_IPS:
        osc_clients.append(udp_client.SimpleUDPClient(ip, port))

def main():
    # get messages
    for window_name in window_states:
        window = window_states[window_name]
        for msg in window:
            addr = "/"+window_name+"/"+msg
            value = window[msg]
            #print(addr+" : "+str(value))
            for osc in osc_clients:
                osc.send_message(addr, value)

# get windowNameList from command line
for i in range(1, len(sys.argv)):
    arg = sys.argv[i]
    print("arg " + arg)
    window_names.append(arg)

for window_name in window_names:
    window_states[window_name] = {}
    emulators_mmf[window_name] = mmap.mmap(-1, MMF_SIZE, window_name + "_in")
    emulator_input[window_name] = {}

c = 0
for game in emulator_input:
    write_emu_input(game)

try:
    while True:
        # read game state from file
        # TODO: pull more smart
        start = time.time()
        for window_name in window_states:
            with mmap.mmap(-1, MMF_SIZE, window_name+"_state", mmap.ACCESS_READ) as mm:
                try:
                    b = mm.read(MMF_SIZE)
                    s = b.decode("utf-8").replace("\x00", "").strip()
                    if len(s) == 0:
                        continue
                    state = json.loads(s)
                    window_states[window_name] = state
                except:
                    print("something went wrong...")

        main()

        end = time.time()
        period = 1/30
        wait = end - start -period
        if wait > 0:
            time.sleep(wait)

except:
    print("Closing resources...")
    mm.close()
    for mmf in emulators_mmf:
        emulators_mmf.close()
