# FTH Gold - Smart Contract Build System
# Comprehensive Makefile for building, testing, and deploying FTH Gold smart contracts

.PHONY: help install build test clean coverage deploy lint format docs

# Default target
help: ## Show available commands
	@echo "FTH Gold Smart Contract Build System"
	@echo "===================================="
	@echo ""
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Contract directory
CONTRACT_DIR := smart-contracts/fth-gold

install: ## Install all dependencies
	@echo "Installing Foundry dependencies..."
	forge install --no-commit
	git submodule update --init --recursive
	@echo "Dependencies installed successfully."

build: install ## Build all smart contracts  
	@echo "Building FTH Gold smart contracts..."
	cd $(CONTRACT_DIR) && forge build --sizes
	@echo "Build completed successfully."

test: install ## Run all tests
	@echo "Running FTH Gold test suite..."
	cd $(CONTRACT_DIR) && forge test -vvv
	@echo "Tests completed."

test-gas: install ## Run tests with gas reporting
	@echo "Running tests with gas reporting..."
	cd $(CONTRACT_DIR) && forge test --gas-report
	@echo "Gas report completed."

coverage: install ## Generate test coverage report
	@echo "Generating coverage report..."
	cd $(CONTRACT_DIR) && forge coverage --report lcov
	@echo "Coverage report generated."

lint: install ## Run linting and static analysis
	@echo "Running static analysis..."
	cd $(CONTRACT_DIR) && forge fmt --check
	@echo "Linting completed."

format: install ## Format code
	@echo "Formatting Solidity code..."
	cd $(CONTRACT_DIR) && forge fmt
	@echo "Code formatted."

snapshot: install ## Generate gas snapshots
	@echo "Generating gas snapshots..."
	cd $(CONTRACT_DIR) && forge snapshot
	@echo "Gas snapshots generated."

clean: ## Clean build artifacts
	@echo "Cleaning build artifacts..."
	cd $(CONTRACT_DIR) && forge clean
	rm -rf $(CONTRACT_DIR)/out
	rm -rf $(CONTRACT_DIR)/cache
	@echo "Clean completed."

deploy-local: build ## Deploy to local network (requires anvil)
	@echo "Deploying to local network..."
	cd $(CONTRACT_DIR) && forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast
	@echo "Local deployment completed."

deploy-testnet: build ## Deploy to testnet (requires PRIVATE_KEY and RPC_URL env vars)
	@echo "Deploying to testnet..."
	cd $(CONTRACT_DIR) && forge script script/Deploy.s.sol --rpc-url $$RPC_URL --broadcast --verify
	@echo "Testnet deployment completed."

anvil: ## Start local Anvil node
	@echo "Starting Anvil local node..."
	anvil

docs: ## Generate documentation
	@echo "Generating documentation..."
	cd $(CONTRACT_DIR) && forge doc
	@echo "Documentation generated."

verify: build ## Verify contract integrity
	@echo "Running comprehensive verification..."
	$(MAKE) lint
	$(MAKE) test
	$(MAKE) coverage
	@echo "Verification completed successfully."

# Development workflow
dev: ## Development workflow - build, test, format
	$(MAKE) format
	$(MAKE) build
	$(MAKE) test

# Production workflow  
prod: ## Production workflow - comprehensive checks
	$(MAKE) clean
	$(MAKE) verify
	$(MAKE) snapshot
	@echo "Production checks completed. Ready for deployment."

# Setup for new developers
setup: ## Setup development environment
	@echo "Setting up FTH Gold development environment..."
	@echo "1. Installing dependencies..."
	$(MAKE) install
	@echo "2. Running initial build..."
	$(MAKE) build
	@echo "3. Running tests to verify setup..."
	$(MAKE) test
	@echo ""
	@echo "✅ Development environment setup complete!"
	@echo "🚀 Run 'make help' to see available commands"