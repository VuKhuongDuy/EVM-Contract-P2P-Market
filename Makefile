.PHONY: analyze test upgradeability

analyze:
	@echo "Running Aderyn analysis..."
	-aderyn .

	@echo "Running Slither analysis..."
	slither .

test:
	@echo "Running Forge tests..."
	forge test

upgradeability:
	@echo "Checking upgradeability with Slither..."
	slither-check-upgradeability ./src/Market.sol P2PMarket
