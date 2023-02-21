# https://github.com/Ashafix/PyEmuHawk/blob/master/PyEmuhawk.py

import mmap
import sys
import json
import threading

from pythonosc import udp_client
from pythonosc.dispatcher import Dispatcher
from pythonosc import osc_server

SOCKET_PORT = 6969
HTTP_PORT = 9876
OSC_SERVER_PORT = 4199
OSC_INITIAL_PORT = 4200
OSC_PORTS = 4
OSC_IPS = [
    "192.168.1.168",
    "192.168.1.166",
]
LOCAL_IP = "192.168.1.166"

osc_input = {
    "test": "10"
}

MMF_SIZE = 1000

# total arguments
n = len(sys.argv)

emulator_input = {}

window_sates = {}

games_mmf  = {}

# get arguments passed in command line
window_names = ["track1", "track2", "track3", "track4"]

print("Creating OSC server")
def emu_handler(address, *args):
    sub = address.split('/')
    game = sub[2]
    state = sub[3]
    value = args[0]
    print("OSC received: ", address, " | setting ", game, "-", state, "to ", value)
    emulator_input[game][state] = value

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
    for window_name in window_sates:
        window = window_sates[window_name]
        for msg in window:
            addr = "/"+window_name+"/"+msg
            value = window[msg]
            for osc in osc_clients:
                osc.send_message(addr, value)

# get windowNameList from command line
for i in range(1, len(sys.argv)):
    arg = sys.argv[i]
    print("arg " + arg)
    window_names.append(arg)

for window_name in window_names:
    window_sates[window_name] = {}
    games_mmf[window_name] = mmap.mmap(-1, MMF_SIZE, window_name + "_in")
    emulator_input[window_name] = {}

c = 0
while True:
    # read game state from file
    for window_name in window_sates:
        with mmap.mmap(-1, MMF_SIZE, window_name+"_state", mmap.ACCESS_READ) as mm:
            try:
                b = mm.read(MMF_SIZE)
                s = b.decode("utf-8").replace("\x00", "").strip()
                if len(s) == 0:
                    continue
                state = json.loads(s)
                window_sates[window_name] = state
            except:
                print("something went wrong...")

    main()


    # write emulator input to file
    for window_name in emulator_input:
            # write emulator input to file
            mm = games_mmf[window_name]
            i = json.dumps(emulator_input[window_name])
            b = bytes(i, "utf-8")

            mm.seek(0)
            #mm.write(bytes([b"\x00"]*MMF_SIZE))
            #mm.seek(0)
            mm.write(b)
            mm.flush()

print("Closing resources")
mm.close()
