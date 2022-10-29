import math
import threading

IP = "192.168.1.166"
OSC_OUT_PORT = 4199
OSC_IN_PORT = 4201

from pythonosc import dispatcher
from pythonosc import osc_server
from pythonosc import udp_client

client = udp_client.SimpleUDPClient(IP, OSC_OUT_PORT)

def handler(addr, args):
    # client.send_message("/filter", random.random())
    if addr == "/zelda/velY":
        client.send_message("/emu/mario/a", args > 0)
    print(addr, args)

dispatcher = dispatcher.Dispatcher()
dispatcher.map("/*", handler)

server = osc_server.ThreadingOSCUDPServer(
    (IP, OSC_IN_PORT), dispatcher)

print("Serving on {}".format(server.server_address))
server.serve_forever()
oscServer_thread = threading.Thread(target=server.serve_forever)