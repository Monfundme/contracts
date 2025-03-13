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
      title: "Trying out withdrawal",
      description: "Trying out withdrawal",
      image: "https://hadassahbridals.com.ng/wp-content/uploads/2024/01/WhatsApp-Image-2023-07-29-at-12.05.46-1-600x799.jpg",
      target: parseEther("10"), // 1 MON
      // deadline: 1741993540// 24 hours from now
      deadline: Math.floor(Date.now() / 1000) + 50400 // 24 hours from now
    };

    // Proposal configuration
    const proposalConfig: ProposalConfig = {
      proposalId: keccak256(toUtf8Bytes("001")), // Generate unique proposal ID
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
