build:
	docker build -t jmcarbo/cloud9 .

run:
	#docker run -ti --rm --cap-add=SYS_ADMIN -e USER=bla -e USERID=10001 -e PASSWORD=bla -p 8181:8181 -v $$PWD/data:/home/bla jmcarbo/cloud9
	docker run -ti --rm  --privileged -e USER=bla -e USERID=10001 -e PASSWORD=bla -p 8181:8181 -v $$PWD/data:/home/bla jmcarbo/cloud9
	#docker run -ti --rm -e USER=bla -e USERID=10001 -e PASSWORD=bla -p 8181:8181 -v $$PWD/data:/home/bla --privileged docker:dind

push:
	docker push jmcarbo/cloud9
