.PHONY: run run-dev run-prod dev prod

run:
	@mode="$(word 2,$(MAKECMDGOALS))"; \
	if [ -z "$$mode" ] || [ "$$mode" = "dev" ]; then \
		cp .env.local.example .env && sh scripts/dev-url.sh && trap 'sh scripts/dev-stop.sh' INT TERM EXIT && flutter run; \
	elif [ "$$mode" = "prod" ]; then \
		cp .env.production.example .env && flutter run; \
	else \
		echo "Usage: make run dev|prod"; \
		exit 1; \
	fi

run-dev:
	cp .env.local.example .env && sh scripts/dev-url.sh && trap 'sh scripts/dev-stop.sh' INT TERM EXIT && flutter run

run-prod:
	cp .env.production.example .env && flutter run

dev prod:
	@:
