build:
	docker build -t jmcarbo/cloud9 .

run:
	docker run -ti --rm -e USER=bla -e USERID=10001 -e PASSWORD=bla -p 8181:8181 -v $$PWD/data:/home/bla jmcarbo/cloud9
