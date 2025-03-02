import { JsonRpcProvider, Wallet, ContractFactory } from "ethers";
import { config } from "dotenv";
config();

import art from "../artifacts/contracts/Monfundme.sol/Monfundme.json";

const provider = new JsonRpcProvider(process.env.RPC_URL);
const wallet = new Wallet(process.env.P_KEY as string, provider);

const deploy = async () => {
	console.log("starting...");

	const conctractFactory = new ContractFactory(art.abi, art.bytecode, wallet);
	const ca = await conctractFactory.deploy();

	await ca.waitForDeployment();

	console.log("Contract deployed to ---- ", await ca.getAddress());
};

deploy();
