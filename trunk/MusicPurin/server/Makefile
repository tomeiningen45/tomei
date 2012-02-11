ROOT = ../src/com/tomei/musicpurin


FILES = $(ROOT)/Utils.java \
        $(ROOT)/WifiServer.java

all:
	rm -rf classes	
	mkdir classes
	javac -d classes ${FILES}
	cd classes; jar cvf ../WifiServer.jar .
	cp -v WifiServer.jar mac/server

