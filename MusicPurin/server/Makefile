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
	cmp doit.sh mac/server/doit.sh || cp -v doit.sh ../../mac/server


test:
	java -Dfile.encoding=UTF-8 -classpath WifiServer.jar com.tomei.musicpurin.WifiClient 192.168.2.80 /tmp/purin


