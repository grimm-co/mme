Man-in-the-middle Made Easy

Don't like memorizing all the flags for iptables?  Yeah, us either.  That's why
we wrapped them in little scripts.  No more trying to recall syntax, or having
to type out long commands.

mutator-proxy.py is a tool to fuzz any server which uses TCP.  It listens on a
local port and mutates the data it receives before sending it off to a server.
So to use it, you set up your client to point to localhost:<server_port> and 
set the proxy to forward traffic to a legitimate server.  If you can't change
the server your client uses, you can just use the other scripts on here to
forcefully hijack a port and redirect it to localhost:<server_port>.  The
random mutation is deterministic, so as long as you can set your seed value and
get the client to do the same thing repeatedly, reproducing crashes should not
be difficult.  There's also an option to save all the bytes which were sent to
the server to disk.  As long as the server is determinstic, this should provide
another path to reproducing crashes and it'll also get the client out of the
loop and let you manually inspect the data which caused the crash.

