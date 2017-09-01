#!/usr/bin/env python3
from struct import pack, unpack
from binascii import hexlify

TLS_TYPE_HANDSHAKE = 0x16
TLS_TYPE_CLIENT_HELLO = 0x01
TLS_SERVER_NAME_EXT = b"\x00\x00"
TLS_STATUS_REQUEST_EXT = b"\x00\x05"
TLS_SIGNED_CERTIFICATE_TIMESTAMP_EXT = b"\x00\x12"
TLS_1_0 = b"\x03\x01"
TLS_1_2 = b"\x03\x03"

# Thanks StackOverflow!
# http://stackoverflow.com/questions/17832592/extract-server-name-indication-sni-from-tls-client-hello

class TlsHandshake:
	def __init__(self):
		self.content_type = b"\x16"
		self.version = TLS_1_0
		self.length = None
		self.data = None

	def __len__(self):
		"""
		This will return the actual length of the packet to be emitted, it pays no
		attention to the self.length value.  Also, it's important to remember that
		this method calculates the length of the entire packet, not just the length
		of the payload.
		"""
		n = 5
		if self.data:
			n += len(self.data)
		return n

	def emit(self):
		b = b""
		b += self.content_type
		b += self.version
		if self.length is None:
			# The -5 is to compensate for the space taken up by the content type,
			# version and length fields
			b += pack(">H", len(self)-5)
		else:
			b += pack(">H", self.length)
		if self.data:
			b += self.data.emit()
		return b
		
class ClientHello():
	def __init__(self, other=None):
		self.handshake_type = b"\x01"
		self.length = None
		self.version = b""
		self.random = b""
		self.session_id = None
		self.cipher_suites = b""
		self.compression_methods = b""
		self.extension_data = []

	def __len__(self):
		"""
		This will calculate the value which should be in the length field based on
		the data.  This may or may not match the value in the length field.
		"""
		# handshake_type = 1 byte
		# length = 3 bytes
		# version = 2 bytes
		# random = 32-bytes
		# session_id = 1 byte for size, more bytes for data
		l = 1 + 3 + 2 + 32 + 1
		if self.session_id is not None:
			l += len(self.session_id)
		# 2 bytes for the size of cipher suites block
		# 1 byte for the size of compression methods
		l += 2 + len(self.cipher_suites) + 1 + len(self.compression_methods)
		if self.extension_data:
			l += 2  # Length of the extension block
			l += self.calculate_extensions_length()
		return l

	def calculate_extensions_length(self):
		return sum([len(x.data) + 4 for x in self.extension_data])

	def emit(self):
		b = b""
		b += self.handshake_type
		if self.length is None:
			# The -4 is to exclude the space for the handshake type and length fields
			b += pack(">I", len(self)-4)[1:4]
		else:
			b += pack(">I", self.length)[1:4]
		b += self.version
		b += self.random
		if self.session_id is not None:
			b += pack("B", len(self.session_id))
			b += self.session_id
		else:
			b += b"\00"  # If there's no session_id, the length is zero
		b += pack(">H", len(self.cipher_suites))
		b += self.cipher_suites
		b += pack("B", len(self.compression_methods))
		b += self.compression_methods
		if self.extension_data:
			b += pack(">H", self.calculate_extensions_length())
			for x in self.extension_data:
				b += x.emit()
		return b

class TlsExtension():
	def __init__(self, extension_type, length, data):
		"""
		If length is None, we will automatically calculated it based on
		the value of the data.  If an integer is passed in for the length,
		we will use that value, regardless of the actual size of the data.
		"""
		self.extension_type = extension_type
		self.length = length
		self.data = data

	def __str__(self):
		return "{extension_type: %s, length: %d, data: %s}" % (
			hexlify(self.extension_type), self.length, self.data)

	def emit(self):
		b = b""
		b += self.extension_type
		if self.length is None:
			b += pack(">H", len(self.data))
		else:
			b += pack(">H", self.length)
		b += self.data
		return b

def parse(data):
	"""
	Takes binary data, detects the TLS message type, parses the info into a nice
	Python object, which is what is returned.
	"""
	if data[0] == TLS_TYPE_HANDSHAKE:
		obj = TlsHandshake()
		obj.version = data[1:3]
		obj.length = unpack(">H", data[3:5])[0]
		if data[5] == TLS_TYPE_CLIENT_HELLO:
			obj.data = ClientHello()
			obj.data.length = unpack(">I", (b"\x00" + data[6:9]))[0]  # 3-byte length
			obj.data.version = data[9:11]
			obj.data.random = data[11:43]  # 32 bytes of random
			if data[43] == 0x00:
				obj.data.session_id = None
			else:
				obj.data.session_id = data[44:44+data[43]]
			offset = 44 + data[43]

			cipher_suite_length = unpack(">H", data[offset:offset+2])[0]
			offset += 2
			obj.data.cipher_suites = data[offset:offset+cipher_suite_length]
			offset += cipher_suite_length

			obj.data.compression_methods = data[offset+1:offset+data[offset]+1]
			offset += 1 + data[offset]

			extensions_length = unpack(">H", data[offset:offset+2])[0]
			offset += 2
			extension_data = data[offset:]
			obj.data.extension_data = []
			while len(extension_data):
				extension, extension_data = parse_tls_extension(extension_data)
				obj.data.extension_data.append(extension)
			return obj
		raise NotImplemented("Only CLIENT_HELLO handshake message is currently implemented")
	raise NotImplemented("Only handshake messages are currently implemented")

def parse_tls_extension(data):
	"""
	This parses one extension from the given data (which may contain
	multiple extension records).

	:returns: parsed object along with unparsed data
	:rtype: 2-element tuple containing a `py:TlsExtension` object and the
		remaining data which has not yet been parsed
	"""
	t = data[0:2]
	length = unpack(">H", data[2:4])[0]
	extension_data = data[4:4+length]
	data = data[4+length:]
	ext = TlsExtension(t, length, extension_data)
	return ext, data

if __name__ == "__main__":
	# This is an example which contains SNI
	data = b"\x16\x03\x01\x00\xa9\x01\x00\x00\xa5\x03\x03\x56\xe0\x9e\x31\x62\x86\x76\x0d\x3b\xfe\x50\x3d\xc4\xa6\x7b\xd4\xfe\xce\xb7\xd8\x72\x98\x97\xa4\xeb\x7a\x37\xf1\xea\xca\xa9\x0c\x00\x00\x34\x00\xff\xc0\x2c\xc0\x2b\xc0\x24\xc0\x23\xc0\x0a\xc0\x09\xc0\x08\xc0\x30\xc0\x2f\xc0\x28\xc0\x27\xc0\x14\xc0\x13\xc0\x12\x00\x9d\x00\x9c\x00\x3d\x00\x3c\x00\x35\x00\x2f\x00\x0a\xc0\x07\xc0\x11\x00\x05\x00\x04\x01\x00\x00\x48\x00\x00\x00\x13\x00\x11\x00\x00\x0e\x62\x61\x64\x65\x78\x61\x6d\x70\x6c\x65\x2e\x6e\x65\x74\x00\x0a\x00\x08\x00\x06\x00\x17\x00\x18\x00\x19\x00\x0b\x00\x02\x01\x00\x00\x0d\x00\x0e\x00\x0c\x05\x01\x04\x01\x02\x01\x05\x03\x04\x03\x02\x03\x00\x05\x00\x05\x01\x00\x00\x00\x00\x00\x12\x00\x00"
	# This is an example which does not include SNI
	#data = b"\x16\x03\x01\x00\x96\x01\x00\x00\x92\x03\x03\x4d\x5b\x63\x52\x7f\xeb\x4c\x77\x98\xa3\x5a\xb7\xde\x20\x33\x3f\x2a\xa6\x30\xd8\xf3\xf1\x75\x2b\x83\x62\x3c\x4b\x6a\x7f\xe1\x2c\x00\x00\x38\xc0\x2b\xc0\x2f\xc0\x0a\xc0\x09\xc0\x13\xc0\x23\xc0\x27\xc0\x14\x00\x9e\x00\x33\x00\x32\x00\x67\x00\x39\x00\x38\x00\x6b\x00\x16\x00\x13\x00\x66\x00\x9c\x00\x2f\x00\x3c\x00\x35\x00\x3d\x00\x0a\x00\x05\x00\x04\x00\x15\x00\x12\x01\x00\x00\x31\xff\x01\x00\x01\x00\x00\x0a\x00\x08\x00\x06\x00\x17\x00\x18\x00\x19\x00\x0b\x00\x02\x01\x00\x00\x0d\x00\x16\x00\x14\x04\x01\x05\x01\x06\x01\x02\x01\x04\x03\x05\x03\x06\x03\x02\x03\x04\x02\x02\x02"

	tls_obj = parse(data)
	assert(data == tls_obj.emit())
	print("\n".join([str(x) for x in tls_obj.data.extension_data]))
