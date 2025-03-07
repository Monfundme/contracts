import { JsonRpcProvider, Wallet, ContractFactory } from "ethers";
import { config } from "dotenv";
config();

import { select, input } from "input";

type contractType = "factory" | "vote_executor"

const provider = new JsonRpcProvider(process.env.RPC_URL);
const wallet = new Wallet(process.env.P_KEY as string, provider);

const deploy = async () => {
	console.log("starting...");

	const contractType: contractType = await select("Select the contract to deploy", {
		factory: "Factory",
		vote_executor: "Vote Executor",
	});

	if (contractType === "vote_executor") {
		const inputFactory = await input.text("Enter the factory address");	

		const art: any = import("../artifacts/contracts/MonfundmeFactory.sol/MonfundmeFactory.json");
		const factory = new ContractFactory(art.abi, art.bytecode, wallet);
		const ca = await factory.deploy(inputFactory);

		await ca.waitForDeployment();

		console.log("Vote Executor Contract deployed to ---- ", await ca.getAddress());
	}else {
		const art: any = await import("../artifacts/contracts/MonfundmeFactory.sol/MonfundmeFactory.json");
		const factory = new ContractFactory(art.abi, art.bytecode, wallet);
		const ca = await factory.deploy();

		await ca.waitForDeployment();
		console.log(" Factory Contract deployed to ---- ", await ca.getAddress());
	}

};

deploy();
