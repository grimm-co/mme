#!/usr/bin/env python3
import select
import socket 

RECV_BUFFER_SIZE = 1024 
REDACTION_STRING = b"<starttls xmlns='urn:ietf:params:xml:ns:xmpp-tls'><required/></starttls>"

def create_socket(host, port, listen=False):
	backlog = 5 
	s = socket.socket(socket.AF_INET, socket.SOCK_STREAM) 
	if listen:
		s.bind((host,port)) 
		s.listen(backlog) 
	else:
		s.connect((host,port)) 
	return s

def main(port, remote_host, remote_port):
	print("About to listen on port %d" % port)
	client_sock = create_socket('', port, listen=True)
	print("Listening on port %d" % port)
	server_sock = create_socket(remote_host, remote_port)
	print("Connecting to remote host %s port %d" % (remote_host, remote_port))

	while True: 
		client, address = client_sock.accept() 
		print("[CLIENT] Connected from %s" % address[0])

		everything_is_OK = True
		while everything_is_OK:
			inputs = [server_sock, client]
			readable, writable, exceptional = select.select(inputs, [], inputs)
			# Handle inputs
			for r in readable:
				if r == client:
					try:
						data = r.recv(RECV_BUFFER_SIZE) 
						print("[CLIENT] %s" % data)
						if data == b"":
							raise BrokenPipeError()
						server_sock.send(data)
						print("Data sent to server")
					except BrokenPipeError:
						print("Connection lost, closing client connect")
						everything_is_OK = False
						try:
							client.close()
							print("Client connection closed")
						except:
							pass
						try:
							server_sock.close()
							print("Server connection closed")
						except:
							pass
						break
				elif r == server_sock:
					data = r.recv(RECV_BUFFER_SIZE) 
					# Sometimes select says the socket for the server is ready to read data
					# from, but if we do so and there's nothing there, that indicates that
					# something went wrong.  So we update our flag accordingly
					everything_is_OK = (data != b"")

					print("[SERVER] %s" % data)
					if REDACTION_STRING in data: 
						offset = data.find(REDACTION_STRING)
						data = (data[:offset] + data[offset+len(REDACTION_STRING):])
						print("[MODIFIED] %s" % data)
					client.send(data) 
					print("Data sent to client")
			# Handle "exceptional conditions"
			for s in exceptional:
				print('Exceptional condition caused by %s' % s.getpeername())
				inputs.remove(s)
				s.close()
				everything_is_OK = False

if __name__ == "__main__":
	print("Started program")
	main(port=8082, remote_host="1.2.3.4", remote_port=5223)
