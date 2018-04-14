default: test

.PHONY: test
test:
	@echo "Running Tests"
	@truffle test

tmr:
	@echo "Resetting & deploying contract."
	@truffle migrate --reset

serve:
	@echo "Running dev server"
	@npm run dev

install:
	@echo "Installing dependencies"
	@npm install
