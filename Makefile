MAKEFLAGS += --silent

clean:
	docker-compose rm -f

build: clean
	docker-compose build

run: build
	docker-compose up

deploy: build
	docker-compose up -d

kill:
	docker-compose down
