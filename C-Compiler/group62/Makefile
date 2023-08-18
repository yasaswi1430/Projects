CXX   = g++-8
EXE = iplC
CXXDEBUG = -g -Wall
CXXSTD = -std=c++11


.PHONY: all parser lexer
all: parser lexer symtab type	
	$(CXX) $(CXXDEBUG) $(CXXSTD) -o $(EXE) driver.cpp parser.o scanner.o symtab.o type.o

symtab: symtab.cpp
	$(CXX) $(CXXDEBUG) $(CXXSTD) -c symtab.cpp -o symtab.o

type: type.cpp
	$(CXX) $(CXXDEBUG) $(CXXSTD) -c type.cpp -o type.o

parser: parser.yy scanner.hh
	bison -d -v $<
	$(CXX) $(CXXDEBUG) $(CXXSTD) -c parser.tab.cc -o parser.o 

lexer: scanner.l scanner.hh parser.tab.hh parser.tab.cc	
	flex++ --outfile=scanner.yy.cc  $<
	$(CXX)  $(CXXDEBUG) $(CXXSTD) -c scanner.yy.cc -o scanner.o

clean: 
	rm -rf parser.tab.cc parser.tab.hh scanner.yy.cc scanner.o parser.o parser.output $(EXE) position.hh stack.hh symtab.o type.o
