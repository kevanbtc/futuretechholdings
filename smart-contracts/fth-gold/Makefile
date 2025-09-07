include .env

simulate:
\tforge script script/Deploy.s.sol --fork-url $(RPC_URL) -vvvv

deploy:
\tforge script script/Deploy.s.sol --rpc-url $(RPC_URL) --private-key $(DEPLOYER_PK) --broadcast -vvvv

verify:
\tforge script script/Deploy.s.sol --rpc-url $(RPC_URL) --private-key $(DEPLOYER_PK) --broadcast --verify -vvvv
