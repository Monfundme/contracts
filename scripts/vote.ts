import { Wallet, JsonRpcProvider, Contract, toUtf8Bytes, keccak256, parseEther } from "ethers";
import { monfundme_vote_executor } from "../contstants";
import dotenv from "dotenv";
import { CampaignParams, ProposalConfig } from "../types";
dotenv.config();

const provider = new JsonRpcProvider(process.env.RPC_URL);
const wallet = new Wallet(process.env.P_KEY as string, provider);

const voteExecutorArt = require("../artifacts/contracts/VoteExecutor.sol/VoteExecutor.json");

const voteExecutor = new Contract(monfundme_vote_executor, voteExecutorArt.abi, wallet);

const main = async () => {
  try {
    console.log("Creating proposal...");
    const campaignParams: CampaignParams = {
      campaignOwner: "0xF519363b26ab80f22C953e27DB1E1b9E053d1A34",
      metadataHash: keccak256(toUtf8Bytes("TEST 2")),
      target: parseEther("1"), // 1 MON
      deadline: Math.floor(Date.now() / 1000) + 86400 // 24 hours from now
    };

    // Proposal configuration
    const proposalConfig: ProposalConfig = {
      proposalId: keccak256(toUtf8Bytes("2")), // Generate unique proposal ID
      startTime: Math.floor(Date.now() / 1000) + 300, //300 milliseconds 
      endTime: Math.floor(Date.now() / 1000) + 2 * 1000, // 2 seconds
      campaignParams: campaignParams
    };

    const proposalTx = await voteExecutor.createProposal(
      proposalConfig.proposalId,
      proposalConfig.startTime,
      proposalConfig.endTime,
      proposalConfig.campaignParams
    );
    await proposalTx.wait();
    console.log("Proposal created...", proposalTx.hash);

    console.log("Voting params...", proposalConfig);

  } catch (error) {
    console.log("Error ---- ", error);
  }
};

main();
