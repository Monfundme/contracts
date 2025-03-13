import { Contract, Wallet, JsonRpcProvider, formatEther } from "ethers";
import { monfundme_factory } from "../contstants";
import dotenv from "dotenv";

dotenv.config();

const provider = new JsonRpcProvider(process.env.RPC_URL);
const wallet = new Wallet(process.env.P_KEY as string, provider);

const factoryArt = require("../artifacts/contracts/MonfundmeFactory.sol/MonfundmeFactory.json");
const campaignArt = require("../artifacts/contracts/MonfundmeFactory.sol/MonfundmeCampaign.json");

const factory = new Contract(monfundme_factory, factoryArt.abi, wallet);

const main = async () => {
    try {
        console.log("checking campaigns... ")
        const deployedCampaigns = await factory.getDeployedCampaigns();
        console.log("Total campaigns:", deployedCampaigns.length);

        // Fetch details for each campaign
        for (const campaignAddress of deployedCampaigns) {
            const campaign = new Contract(campaignAddress, campaignArt.abi, wallet);

            // Get campaign details
            const campaignDetails = await campaign.campaign();

            console.log(" --------------------------------------------------------------");
            console.log("Address:", campaignAddress);
            console.log("Owner:", campaignDetails.owner);
            console.log("Target:", formatEther(campaignDetails.target));
            console.log("Deadline:", new Date(Number(campaignDetails.deadline) * 1000).toLocaleString());
            console.log("Amount Collected:", formatEther(campaignDetails.amountCollected));
            console.log("title:", campaignDetails.title);
            console.log("description:", campaignDetails.description);
            console.log("image:", campaignDetails.image);
            console.log(" --------------------------------------------------------------");
        }

    } catch (error) {
        console.error("Error:", error);
    }
};

main().catch(console.error);

