#!/usr/bin/env python
from argparse import ArgumentParser
from logging import DEBUG, INFO, debug, info, error, basicConfig
from random import random, seed
from select import select
from socket import socket, AF_INET, SOCK_STREAM

BUFFER_SIZE=1024

def connect_to_dest(host, port):
	s = socket(AF_INET, SOCK_STREAM)
	s.connect((host, port))
	return s

def start_server(port):
	serversocket = socket(AF_INET, SOCK_STREAM)
	serversocket.bind(("", port))
	serversocket.listen(1) # one connection at a time!
	return serversocket

def mutate(character, mod_percentage):
	if random() < mod_percentage:
		debug("Modified a byte")
		return int(random() * 255)
	if type(character) == int: # Python 3
		return character
	return ord(character)      # Python 2

def fuzz(dest_host, dest_port, server_port, mod_percentage, outfile):
	bound_socket = start_server(server_port)
	(client_socket, address) = bound_socket.accept()
	info("Received connection from client: %s" % repr(address))
	server_socket = connect_to_dest(dest_host, dest_port)
	info("Connected to port %d on the server %s" % (dest_port, dest_host))

	while True:
		(readfds, writefds, exceptfds) = select([client_socket, server_socket], [], [client_socket, server_socket])
		for fd in readfds:
			chunk = fd.recv(BUFFER_SIZE)
			if fd == client_socket:
				if len(chunk) == 0: # this mean the socket has gone away
					raise RuntimeError("Client socket error.  Client disconnected")
				debug("Read %d bytes from the client" % len(chunk))

				# if we read from the client, mutate it and send it to the server
				mutant_data = []
				for b in chunk:
					mutant_data.append(mutate(b, mod_percentage))

				# Casting to bytes in Python 3 does what you'd expect, in Python 2 it converts to str(repr(mutant_data))
				mutant_data_bytes = bytes(mutant_data)
				if mutant_data_bytes[0] != mutant_data[0]: # this happens in Python 2, so we need to patch it up properly
					mutant_data_bytes = "".join(chr(x) for x in mutant_data)

				# Write out our mutant data
				outfile.write(mutant_data_bytes)
				server_socket.sendall(mutant_data_bytes)
			else:
				if len(chunk) == 0: # this mean the socket has gone away
					raise RuntimeError("Server socket error.  Server disconnected")
				debug("Read %d bytes from the server" % len(chunk))

				# if we read from the server, just send it to the client as is
				client_socket.sendall(chunk)

		for fd in exceptfds:
			if fd == client_socket:
				raise RuntimeError("Client socket error")
			raise RuntimeError("Server socket error")

if __name__ == "__main__":
	parser = ArgumentParser(description='Proxies a TCP connection, mutating data from the source (a.k.a. fuzzing) at random.')
	parser.add_argument('server_port', type=int, default=1080,
	                    help='The port on which we should listen for incoming connections')
	parser.add_argument('dest_hostname', type=str, default=None,
	                    help=('The hostname of the server to ultimately connect to.'))
	parser.add_argument('dest_port', type=int, default=80,
	                    help='The destination port')
	parser.add_argument('--random-seed', type=int, default=None,
	                    help='The seed for the randomness (allows for deterministic behavior)')
	parser.add_argument('--modification-percentage', type=float, default=0.01,
	                    help='The odds that a byte will be modified.  Default: 0.01')
	parser.add_argument('--output-filename', type=str, default="/dev/null",
	                    help=('The filename where all bytes should be written (after modifications).  Default: /dev/null'))
	parser.add_argument('-v', action='store_true',
	                    help=('Verbose output (for debugging issues)'))

	args = parser.parse_args()
	if args.random_seed != None:
		random.seed(args.random_seed)
	outfile = open(args.output_filename, "wb")
	basicConfig(format="[%(levelname)s] %(asctime)s - %(message)s", level=(INFO, DEBUG)[args.v])

	debug(repr(args))
	while True:
		try:
			fuzz(args.dest_hostname, args.dest_port, args.server_port, args.modification_percentage, outfile)
		except RuntimeError as e:
			error(str(e))
		except KeyboardInterrupt as e:
			info("Quitting...")
			break
