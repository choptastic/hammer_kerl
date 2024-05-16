install:
	rm /usr/bin/hammer_kerl /usr/bin/erl /usr/bin/escript /usr/bin/erlc
	cp `pwd`/hammer_kerl.pl /usr/bin/hammer_kerl
	ln -s /usr/bin/hammer_kerl /usr/bin/erl
	ln -s /usr/bin/hammer_kerl /usr/bin/escript
	ln -s /usr/bin/hammer_kerl /usr/bin/erlc

