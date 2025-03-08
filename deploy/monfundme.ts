import { JsonRpcProvider, Wallet, ContractFactory } from "ethers";
import { config } from "dotenv";
config();

const provider = new JsonRpcProvider(process.env.RPC_URL);
const wallet = new Wallet(process.env.P_KEY as string, provider);

const deploy = async () => {
	console.log("starting...");

	// Deploying factory contract
	console.log("Deploying Factory Contract");
	const factoryArt = require("../artifacts/contracts/MonfundmeFactory.sol/MonfundmeFactory.json");
	const factory = new ContractFactory(factoryArt.abi, factoryArt.bytecode, wallet);
	const factoryContract = await factory.deploy();
	await factoryContract.waitForDeployment();
	const factoryAddress = await factoryContract.getAddress();
	console.log("Factory Contract deployed to ---- ", factoryAddress);

	// deploying vote executor contract
	console.log("Deploying Vote Executor Contract");

	const voteExecutorArt = require("../artifacts/contracts/VoteExecutor.sol/VoteExecutor.json");
	const voteExecutorFactory = new ContractFactory(voteExecutorArt.abi, voteExecutorArt.bytecode, wallet);

	// const voteExecutor = await voteExecutorFactory.deploy("0xB3CF8637344Bd36108EA25008308A3fD6CcF3e4D");
	const voteExecutor = await voteExecutorFactory.deploy(factoryAddress);
	await voteExecutor.waitForDeployment();
	console.log("Vote Executor Contract deployed to ---- ", await voteExecutor.getAddress());
};

deploy();
