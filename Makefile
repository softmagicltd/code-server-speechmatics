.PHONY: build run stop set-password deploy

build:
	docker compose build

run:
	docker compose up -d

stop:
	docker compose down

set-password:
	@docker compose exec code-server set-password

deploy:
	railway up
