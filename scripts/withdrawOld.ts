import { Contract, JsonRpcProvider, Wallet } from "ethers";
import { monfundme_factory } from "../contstants";
import dotenv from "dotenv";

dotenv.config();

const provider = new JsonRpcProvider(process.env.RPC_URL);
const wallet = new Wallet(process.env.P_KEY as string, provider);

const factoryArt = require("../artifacts/contracts/MonfundmeFactory.sol/MonfundmeFactory.json");
const campaignArt = require("../artifacts/contracts/MonfundmeFactory.sol/MonfundmeCampaign.json");

const factory = new Contract(monfundme_factory, factoryArt.abi, wallet);

const main = async (campaignAddress: string) => {
    try {
        console.log("Starting withdrawal from campaign:", campaignAddress);

        const campaign = new Contract(campaignAddress, campaignArt.abi, wallet);

        // Get campaign details before withdrawal
        const campaignDetailsBefore = await campaign.campaign();
        console.log("Amount collected before withdrawal:", campaignDetailsBefore.amountCollected.toString());

        // Execute withdrawal
        const withdrawTx = await campaign.withdraw();
        await withdrawTx.wait();

        console.log("Successfully withdrew funds from campaign!");
        console.log("Transaction hash:", withdrawTx.hash);

        // Get updated campaign details
        const campaignDetailsAfter = await campaign.campaign();
        console.log("Amount remaining after withdrawal:", campaignDetailsAfter.amountCollected.toString());

    } catch (error) {
        console.error("Error withdrawing from campaign:", error);
    }
};

// Check if campaign address was provided
if (process.argv.length < 3) {
    console.error("Please provide a campaign address as an argument");
    process.exit(1);
}

const campaignAddress = process.argv[2];
main(campaignAddress).catch((error) => {
    console.error(error);
    process.exitCode = 1;
});