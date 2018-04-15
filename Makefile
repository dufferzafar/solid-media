C=\033[1;035m # Color
NC=\033[0m # No Color

BIN=node_modules/.bin/

default: lint test

.PHONY: test
test: ganache
	@printf "$(C)Running tests$(NC)\n"
	@$(BIN)/truffle test

tmr:
	@printf "$(C)Resetting & deploying contract.$(NC)\n"
	@$(BIN)/truffle migrate --reset

solium:
	@printf "$(C)Linting contract with Solium$(NC)\n"
	@$(BIN)/solium --fix -d contracts/

eslint:
	@printf "$(C)Linting tests with ESLint$(NC)\n\n"
	@$(BIN)/eslint --fix test/

lint: solium eslint

serve:
	@printf "$(C)Running dev server$(NC)\n"
	@npm run dev

install:
	@printf "$(C)Installing dependencies$(NC)\n"
	@npm install --dev

.PHONY: ganache
ganache:
	@if ! pgrep ganache >/dev/null 2>&1; then printf "$(C)Ganache not running!$(NC)\n"; fi;
