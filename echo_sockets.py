#!/usr/bin/env python3
"""
A basic demonstration of listening/sending data over TCP.
Spins up two threads:

* A server listening for a single connection on TCP
* A client to send some data over a TCP connection
"""
import socket
import threading

HOST = "127.0.0.1"
PORT = 5000
TERMINATOR = b"bye"


def run_server() -> None:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.bind((HOST, PORT))
        sock.listen()

        conn, addr = sock.accept()
        print(f"Got connection from {addr}")

        with conn:
            while True:
                data = conn.recv(1024)

                print(f"Received {data.decode()}")
                conn.sendall(data)
                print("Sent data")

                if data == TERMINATOR:
                    break


def run_client() -> None:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.connect((HOST, PORT))
        for data in (b"Hello, world!", TERMINATOR):
            sock.sendall(data)
            print(sock.recv(1024))


def main() -> int:
    server_thread = threading.Thread(target=run_server)
    client_thread = threading.Thread(target=run_client)

    for thread in (server_thread, client_thread):
        # There's a race condition here where the client _could_ try and connect
        # before the server is ready
        thread.start()
    client_thread.join()
    server_thread.join()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
