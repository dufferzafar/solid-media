C=\033[1;035m # Color
NC=\033[0m # No Color

default: lint test

.PHONY: test
test: ganache
	@printf "$(C)Running Tests$(NC)\n"
	@truffle test

tmr:
	@printf "$(C)Resetting & deploying contract.$(NC)\n"
	@truffle migrate --reset

lint:
	@printf "$(C)Linting solidity contract with Solium$(NC)\n"
	@solium -d contracts/

serve:
	@printf "$(C)Running dev server$(NC)\n"
	@npm run dev

install:
	@printf "$(C)Installing dependencies$(NC)\n"
	@npm install

.PHONE: ganache
ganache:
	@if ! pgrep ganache >/dev/null 2>&1; then printf "$(C)Ganache not running!$(NC)\n"; fi;
