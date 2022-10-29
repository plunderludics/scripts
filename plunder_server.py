import socket
import sys
import time
import http.server
import threading
import json

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

print("Creating OSC server")
def emu_handler(address, *args):
    sub = address.split('/')
    root = osc_input
    for i in range(2, len(sub)):
        if i == len(sub) - 1:
            root[sub[i]] = args[0]
        else:
            root[sub[i]] = {}
            root = root[sub[i]]

    print("OSC received: ", address, args[0], osc_input)

dispatcher = Dispatcher()
dispatcher.map("/emu/*", emu_handler)
oscServer = osc_server.ThreadingOSCUDPServer((LOCAL_IP, OSC_SERVER_PORT), dispatcher)
oscServer_thread = threading.Thread(target=oscServer.serve_forever)
oscServer_thread.start()

# get the hostname
class SocketServer:
    """
    A simple socket server implementation
    """
    def __init__(self, ip=None, port=6969, timeout=100, no_of_connections=10, logger=sys.stdout, verbose=True):
        # try to autodetect local IP address
        if ip is None:
            self.ip = socket.gethostbyname(socket.gethostname())
        else:
            self.ip = ip
        self.port = port
        self.timeout = timeout
        self.no_of_connections = no_of_connections
        self.serversocket = None
        self.connection = None
        self.address = None
        self.logger = logger
        self.verbose = verbose

        # osc client
        self.osc = None
        self.osc2 = None

        # osc server

    def __print(self, message):
        if self.verbose:
            self.logger.write(message)

    def create_connection(self):
        self.__print('establishing connection at,' + str(self.ip) + ':' + str(self.port) + '\n')
        self.serversocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.serversocket.settimeout(self.timeout)
        self.serversocket.bind((self.ip, self.port))
        self.serversocket.listen(self.no_of_connections)
        self.__print('waiting for connection\n')
        self.connection, self.address = self.serversocket.accept()
        self.__print('{}, {}'.format(self.connection, self.address))
        self.__print('connection finished\n')

        self.osc_clients = []
        for i in range(0, OSC_PORTS):
            port = OSC_INITIAL_PORT + i
            for ip in OSC_IPS:
                self.osc_clients.append(udp_client.SimpleUDPClient(ip, port))

    def connect(self):
        self.connection, self.address = self.serversocket.accept()
        self.__print('{};{}\n'.format(self.connection, self.address))

    def listen(self, run_time=10):

        incoming = b''
        start_time = time.time()

        while run_time < 0 or time.time() - start_time < run_time:
            try:
                buf = self.connection.recv(4096)
            except ConnectionResetError:
                buf = ''

            if len(buf) == 0:
                self.__print('reconnect\n')
                self.connect()
            else:
                # self.__print('SOCKET received: ' + str(buf) + '\n')
                data = str(buf).split(" ", 1)[1]
                for msg in data.split(" "):
                    print(msg)
                    addr = '/'+msg.split(':')[0]
                    valueStr = msg.split(':')[1].replace("'", "")
                    value = float(valueStr)
                    for osc in self.osc_clients:
                        osc.send_message(addr, value)
                    self.__print('OSC sent: ' + addr + ": " + str(value) + '\n')

                incoming += buf


        return incoming

class HttpServerHandler(http.server.BaseHTTPRequestHandler):
    """
    A simple HTTP server capable of handling GET and POST requests
    """
    def _set_headers(self, response=None, connection=None):
        self.send_response(200)
        self.send_header('Content-Type', 'text/html; charset=utf-8')

        if response is not None:
            self.send_header('Content-Length', len(response))
        if connection is not None:
            self.send_header('Connection', connection)
        self.end_headers()

    def do_GET(self):
        self.protocol_version = 'HTTP/1.1'

        response = json.dumps(osc_input).encode()
        self._set_headers(response=response)
        self.wfile.write(response)

    def do_HEAD(self):
        self._set_headers()

    def do_POST(self):
        sys.stdout.write('POST received\n')
        response = b'<html><body>OK</body></html>'
        self.protocol_version = 'HTTP/1.1'
        self._set_headers(response=response, connection='keep-alive')
        self.wfile.write(response)

    def log_message(self, format, *args):
        return


print('Starting HTTP server')
httpd = http.server.HTTPServer(('', HTTP_PORT), HttpServerHandler)
print('Running HTTP server at: {}:{}'.format(httpd.server_address[0], httpd.server_address[1]))
if httpd.server_address[0] == '0.0.0.0':
    print('HTTP server address is {}, probably you can use localhost or {} as its IP address'.format(
        httpd.server_address[0],
        socket.gethostbyname(
            socket.gethostname())
        )
    )
    http_address = 'http://{}:{}'.format(socket.gethostbyname(socket.gethostname()), httpd.server_address[1])
else:
    http_address = 'http://{}:{}'.format(httpd.server_address[0], httpd.server_address[1])

print('Starting http server')
thread_http = threading.Thread(target=httpd.serve_forever)
thread_http.start()

print('Starting socket server')
s = SocketServer(port=SOCKET_PORT)
s.create_connection()
while True:
    s.listen()