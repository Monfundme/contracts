

import { JsonRpcProvider, Wallet, Contract } from "ethers";
import { monfundme_factory, monfundme_vote_executor } from "../contstants";
import dotenv from "dotenv";

dotenv.config();

const provider = new JsonRpcProvider(process.env.RPC_URL);
const wallet = new Wallet(process.env.P_KEY as string, provider);

const voteExecutorArt = require("../artifacts/contracts/VoteExecutor.sol/VoteExecutor.json");
const factoryArt = require("../artifacts/contracts/MonfundmeFactory.sol/MonfundmeFactory.json");

const addValidators = async () => {
    const voteExecutor = new Contract(monfundme_vote_executor, voteExecutorArt.abi, wallet);

    const validatorsArray = [
        new Wallet(process.env.v_1 as string, provider),
        new Wallet(process.env.v_2 as string, provider),
    ]

    for (const validator of validatorsArray) {
        console.log("Adding validator ---- ", validator.address);
        const addValidatorTx = await voteExecutor.addValidator(validator.address);
        await addValidatorTx.wait();
    }

    console.log("Validators added");

}

const updateVoteExecutor = async () => {

    console.log("Update executor ...");
    const factory = new Contract(monfundme_factory, factoryArt.abi, wallet);
    const updateVoteExecutorTx = await factory.setVoteExecutor(monfundme_vote_executor);
    await updateVoteExecutorTx.wait();

    console.log("Vote executor updated");
}


// updateVoteExecutor().catch(console.error);
addValidators().catch(console.error);





