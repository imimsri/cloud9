build:
	docker build -t jmcarbo/cloud9 .

run:
	docker run -ti --rm -p 8181:8181 -v $$PWD:/home/user jmcarbo/cloud9
