CXXFLAGS := -std=c++2a
LDFLAGS := -lfmt

test:: main
	./main

main: main.cpp smtp-address-validator.cpp

smtp-address-validator.cpp: smtp-address-validator.rl
	ragel -o $@ $<

clean::
	rm -f main *.o smtp-address-validator.cpp
