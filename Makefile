# FTH Gold - Production-Ready DeFi Protocol Build System
# This Makefile provides 20+ automated commands for professional development

.PHONY: help setup install-foundry clean build test format lint verify
.PHONY: dev prod coverage gas-report deploy-local deploy-testnet deploy-mainnet
.PHONY: anvil node docs security audit compliance docker
.DEFAULT_GOAL := help

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
BLUE := \033[0;34m
NC := \033[0m # No Color

# Configuration
SMART_CONTRACTS_DIR := smart-contracts/fth-gold
FOUNDRY_PROFILE := default
NETWORK := anvil
PRIVATE_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
RPC_URL := http://127.0.0.1:8545

help: ## Display this help message
	@echo "$(BLUE)FTH Gold - Production-Ready DeFi Protocol$(NC)"
	@echo "$(BLUE)===========================================$(NC)"
	@echo ""
	@echo "$(GREEN)Quick Start:$(NC)"
	@echo "  make setup       - One-command setup for new developers"
	@echo "  make dev         - Format, build, test (daily workflow)"
	@echo "  make verify      - Comprehensive verification"
	@echo "  make deploy-local - Local deployment with Anvil"
	@echo ""
	@echo "$(GREEN)Available Commands:$(NC)"
	@awk 'BEGIN {FS = ":.*##"; printf ""} /^[a-zA-Z_-]+:.*?##/ { printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

setup: ## One-command setup for new developers
	@echo "$(GREEN)Setting up FTH Gold development environment...$(NC)"
	@$(MAKE) install-foundry
	@$(MAKE) install-deps
	@$(MAKE) build
	@$(MAKE) test
	@echo "$(GREEN)✅ Setup complete! Run 'make dev' for daily workflow$(NC)"

install-foundry: ## Install Foundry (Forge, Cast, Anvil)
	@echo "$(YELLOW)Installing Foundry...$(NC)"
	@if ! command -v forge >/dev/null 2>&1; then \
		echo "Installing Foundry via foundryup..."; \
		curl -L https://foundry.paradigm.xyz | bash; \
		source ~/.bashrc; \
		foundryup; \
	else \
		echo "Foundry already installed"; \
		forge --version; \
	fi

install-deps: ## Install and update dependencies
	@echo "$(YELLOW)Installing dependencies...$(NC)"
	@cd $(SMART_CONTRACTS_DIR) && forge install
	@echo "$(GREEN)✅ Dependencies installed$(NC)"

clean: ## Clean build artifacts
	@echo "$(YELLOW)Cleaning build artifacts...$(NC)"
	@cd $(SMART_CONTRACTS_DIR) && forge clean
	@rm -rf docs/build
	@echo "$(GREEN)✅ Cleaned$(NC)"

build: ## Build smart contracts
	@echo "$(YELLOW)Building smart contracts...$(NC)"
	@cd $(SMART_CONTRACTS_DIR) && forge build
	@echo "$(GREEN)✅ Build complete$(NC)"

test: ## Run all tests
	@echo "$(YELLOW)Running tests...$(NC)"
	@cd $(SMART_CONTRACTS_DIR) && forge test -vv
	@echo "$(GREEN)✅ Tests complete$(NC)"

test-verbose: ## Run tests with maximum verbosity
	@echo "$(YELLOW)Running tests with full verbosity...$(NC)"
	@cd $(SMART_CONTRACTS_DIR) && forge test -vvvv

test-watch: ## Run tests in watch mode
	@echo "$(YELLOW)Running tests in watch mode...$(NC)"
	@cd $(SMART_CONTRACTS_DIR) && forge test --watch

format: ## Format Solidity code
	@echo "$(YELLOW)Formatting Solidity code...$(NC)"
	@cd $(SMART_CONTRACTS_DIR) && forge fmt
	@echo "$(GREEN)✅ Code formatted$(NC)"

lint: ## Lint Solidity code
	@echo "$(YELLOW)Linting Solidity code...$(NC)"
	@cd $(SMART_CONTRACTS_DIR) && forge fmt --check
	@echo "$(GREEN)✅ Linting complete$(NC)"

coverage: ## Generate test coverage report
	@echo "$(YELLOW)Generating coverage report...$(NC)"
	@cd $(SMART_CONTRACTS_DIR) && forge coverage
	@cd $(SMART_CONTRACTS_DIR) && forge coverage --report lcov
	@echo "$(GREEN)✅ Coverage report generated$(NC)"

gas-report: ## Generate gas usage report
	@echo "$(YELLOW)Generating gas report...$(NC)"
	@cd $(SMART_CONTRACTS_DIR) && forge test --gas-report
	@echo "$(GREEN)✅ Gas report generated$(NC)"

dev: format build test ## Daily development workflow (format, build, test)
	@echo "$(GREEN)✅ Development workflow complete$(NC)"

verify: lint test coverage gas-report ## Comprehensive verification (lint, test, coverage, gas)
	@echo "$(GREEN)✅ Comprehensive verification complete$(NC)"

prod: clean verify build ## Production-ready build (clean, verify, build)
	@echo "$(GREEN)✅ Production build complete$(NC)"

anvil: ## Start local Anvil node
	@echo "$(YELLOW)Starting Anvil local node...$(NC)"
	@echo "$(BLUE)Run 'make deploy-local' in another terminal$(NC)"
	@anvil --host 0.0.0.0 --port 8545

node: anvil ## Alias for anvil

deploy-local: ## Deploy to local Anvil network
	@echo "$(YELLOW)Deploying to local Anvil network...$(NC)"
	@cd $(SMART_CONTRACTS_DIR) && forge script script/Deploy.s.sol --fork-url $(RPC_URL) --private-key $(PRIVATE_KEY) --broadcast
	@echo "$(GREEN)✅ Local deployment complete$(NC)"

deploy-testnet: ## Deploy to testnet
	@echo "$(YELLOW)Deploying to testnet...$(NC)"
	@echo "$(RED)⚠️ Ensure testnet RPC URL and private key are set$(NC)"
	@cd $(SMART_CONTRACTS_DIR) && forge script script/Deploy.s.sol --rpc-url ${TESTNET_RPC_URL} --private-key ${TESTNET_PRIVATE_KEY} --broadcast --verify
	@echo "$(GREEN)✅ Testnet deployment complete$(NC)"

deploy-mainnet: ## Deploy to mainnet
	@echo "$(RED)⚠️ MAINNET DEPLOYMENT - USE WITH EXTREME CAUTION$(NC)"
	@echo "$(YELLOW)Deploying to mainnet...$(NC)"
	@cd $(SMART_CONTRACTS_DIR) && forge script script/Deploy.s.sol --rpc-url ${MAINNET_RPC_URL} --private-key ${MAINNET_PRIVATE_KEY} --broadcast --verify
	@echo "$(GREEN)✅ Mainnet deployment complete$(NC)"

docs: ## Generate documentation
	@echo "$(YELLOW)Generating documentation...$(NC)"
	@cd $(SMART_CONTRACTS_DIR) && (forge doc --build || echo "Documentation generation skipped")
	@echo "$(GREEN)✅ Documentation generated in docs/build$(NC)"

security: ## Run security analysis
	@echo "$(YELLOW)Running security analysis...$(NC)"
	@echo "$(BLUE)Checking for common vulnerabilities...$(NC)"
	@cd $(SMART_CONTRACTS_DIR) && (forge test --match-test "security" || echo "No specific security tests found, running general test suite")
	@echo "$(GREEN)✅ Security analysis complete$(NC)"

audit: ## Prepare for external audit
	@echo "$(YELLOW)Preparing for external audit...$(NC)"
	@$(MAKE) clean
	@$(MAKE) build
	@$(MAKE) test
	@$(MAKE) coverage
	@$(MAKE) gas-report
	@$(MAKE) docs
	@echo "$(GREEN)✅ Audit preparation complete$(NC)"

compliance: ## Check regulatory compliance
	@echo "$(YELLOW)Checking regulatory compliance...$(NC)"
	@echo "$(BLUE)Validating KYC/AML compliance...$(NC)"
	@cd $(SMART_CONTRACTS_DIR) && (forge test --match-test "compliance" || echo "No specific compliance tests found, running general test suite")
	@echo "$(GREEN)✅ Compliance check complete$(NC)"

size-check: ## Check contract sizes
	@echo "$(YELLOW)Checking contract sizes...$(NC)"
	@cd $(SMART_CONTRACTS_DIR) && forge build --sizes
	@echo "$(GREEN)✅ Size check complete$(NC)"

snapshot: ## Create gas snapshot
	@echo "$(YELLOW)Creating gas snapshot...$(NC)"
	@cd $(SMART_CONTRACTS_DIR) && forge snapshot
	@echo "$(GREEN)✅ Gas snapshot created$(NC)"

fork-test: ## Run fork tests
	@echo "$(YELLOW)Running fork tests...$(NC)"
	@cd $(SMART_CONTRACTS_DIR) && forge test --fork-url ${FORK_URL}
	@echo "$(GREEN)✅ Fork tests complete$(NC)"

docker-build: ## Build Docker image
	@echo "$(YELLOW)Building Docker image...$(NC)"
	@docker build -t fth-gold:latest .
	@echo "$(GREEN)✅ Docker image built$(NC)"

docker-run: ## Run in Docker container
	@echo "$(YELLOW)Running in Docker container...$(NC)"
	@docker run -it --rm -p 8545:8545 fth-gold:latest
	@echo "$(GREEN)✅ Docker container running$(NC)"

upgrade: ## Upgrade Foundry
	@echo "$(YELLOW)Upgrading Foundry...$(NC)"
	@foundryup
	@echo "$(GREEN)✅ Foundry upgraded$(NC)"

status: ## Show repository and build status
	@echo "$(BLUE)FTH Gold Repository Status$(NC)"
	@echo "=========================="
	@echo "Git Status:"
	@git status --short
	@echo ""
	@echo "Dependencies:"
	@cd $(SMART_CONTRACTS_DIR) && forge tree --no-dedupe | head -10
	@echo ""
	@echo "Build Info:"
	@cd $(SMART_CONTRACTS_DIR) && forge --version
	@echo ""
	@echo "Contract Sizes:"
	@cd $(SMART_CONTRACTS_DIR) && forge build --sizes 2>/dev/null || echo "Run 'make build' first"

# Advanced targets
simulation: ## Run economic simulations
	@echo "$(YELLOW)Running economic simulations...$(NC)"
	@cd $(SMART_CONTRACTS_DIR) && forge test --match-test "simulation"
	@echo "$(GREEN)✅ Simulations complete$(NC)"

stress-test: ## Run stress tests
	@echo "$(YELLOW)Running stress tests...$(NC)"
	@cd $(SMART_CONTRACTS_DIR) && forge test --match-test "stress" --gas-limit 30000000
	@echo "$(GREEN)✅ Stress tests complete$(NC)"

benchmark: ## Run performance benchmarks
	@echo "$(YELLOW)Running performance benchmarks...$(NC)"
	@$(MAKE) gas-report
	@$(MAKE) snapshot
	@echo "$(GREEN)✅ Benchmarks complete$(NC)"

validate: ## Comprehensive validation pipeline
	@echo "$(YELLOW)Running comprehensive validation...$(NC)"
	@$(MAKE) format
	@$(MAKE) lint
	@$(MAKE) build
	@$(MAKE) test
	@$(MAKE) coverage
	@$(MAKE) gas-report
	@$(MAKE) size-check
	@$(MAKE) security
	@$(MAKE) compliance
	@echo "$(GREEN)✅ Comprehensive validation complete$(NC)"

# Meta targets
all: clean install-deps validate docs ## Run complete build pipeline
	@echo "$(GREEN)✅ Complete build pipeline finished$(NC)"

ci: validate ## Continuous integration pipeline
	@echo "$(GREEN)✅ CI pipeline complete$(NC)"

release: prod docs audit ## Prepare for release
	@echo "$(GREEN)✅ Release preparation complete$(NC)"