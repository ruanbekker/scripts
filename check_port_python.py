import socket
from contextlib import closing

def check_port(hostname, port):
    data = {}
    with closing(socket.socket(socket.AF_INET, socket.SOCK_STREAM)) as sock:
        if sock.connect_ex((hostname, port)) == 0:
            data = {'hostname': hostname, 'port': port, 'status': 'open'}
        else:
            data = {'hostname': hostname, 'port': port, 'status': 'closed'}
    return data
    
gitea = check_port('192.168.0.250', 3000)
