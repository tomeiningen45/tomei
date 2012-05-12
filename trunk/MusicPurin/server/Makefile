# Run the iTunes -> MusicPurin server on my Mac.
#
# doit2.sh is the correct script to run for starting the server.
#

ROOT = ../src/com/tomei/musicpurin


FILES = $(ROOT)/Utils.java \
        $(ROOT)/WifiServer.java \
        $(ROOT)/WifiClient.java

all:
	rm -rf classes	
	mkdir classes
	javac -d classes ${FILES}
	cd classes; jar cvf ../WifiServer.jar .
	cp -v WifiServer.jar ../../mac/server
	cmp doit.sh ../../mac/server/doit.sh || cp -v doit.sh ../../mac/server
	cmp doit2.sh ../../mac/server/doit2.sh || cp -v doit2.sh ../../mac/server

start:
	ssh ${MAC_USER_NAME}@mac sh /Volumes/USB/server/doit2.sh

test1:
	java -Dfile.encoding=UTF-8 -classpath WifiServer.jar com.tomei.musicpurin.WifiClient 192.168.2.80 /tmp/purin test1


test2:
	java -Dfile.encoding=UTF-8 -classpath WifiServer.jar com.tomei.musicpurin.WifiClient 192.168.2.80 /tmp/purin test2


