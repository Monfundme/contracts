import {
    Contract,
    JsonRpcProvider,
    keccak256,
    toUtf8Bytes,
    Wallet,
    solidityPacked,
    getBytes
} from "ethers";
import { monfundme_vote_executor } from "../contstants";
import dotenv from "dotenv";

dotenv.config();

const provider = new JsonRpcProvider(process.env.RPC_URL);
const wallet = new Wallet(process.env.P_KEY as string, provider);

const voteExecutorArt = require("../artifacts/contracts/VoteExecutor.sol/VoteExecutor.json");

const voteExecutor = new Contract(monfundme_vote_executor, voteExecutorArt.abi, wallet);

const validator1 = new Wallet(process.env.v_1 as string, provider);
const validator2 = new Wallet(process.env.v_2 as string, provider);

const executeVote = async () => {
    try {

        const proposalId = keccak256(toUtf8Bytes("TEST_PROPOSAL"));
        const resultHash = keccak256(toUtf8Bytes("YES_CREATE_THIS_CAMPAIGN"));

        const messageHash = keccak256(
            solidityPacked(
                ["bytes32", "bytes32"],
                [proposalId, resultHash]
            )
        );

        // Get signatures from all validators
        const signatures = [];
        signatures.push(await wallet.signMessage(getBytes(messageHash)));
        signatures.push(await validator1.signMessage(getBytes(messageHash)));
        signatures.push(await validator2.signMessage(getBytes(messageHash)));

        console.log("Executing proposal...");
        const executeTx = await voteExecutor.executeResult(proposalId, resultHash, signatures);
        await executeTx.wait();
        console.log("Proposal executed successfully!");

    } catch (error) {
        console.log("Error ---- ", error);
    }
}

executeVote();