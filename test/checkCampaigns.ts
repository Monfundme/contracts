import { Contract, Wallet, JsonRpcProvider } from "ethers";
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

        const deployedCampaigns = await factory.getDeployedCampaigns();
        console.log("Total campaigns:", deployedCampaigns.length);

        // Fetch details for each campaign
        for (const campaignAddress of deployedCampaigns) {
            const campaign = new Contract(campaignAddress, campaignArt.abi, wallet);

            // Get campaign details
            const campaignDetails = await campaign.campaign();

            console.log(" --------------------------------------------------------------");
            console.log("Address:", campaignAddress);
            console.log("Name:", campaignDetails.name);
            console.log("Owner:", campaignDetails.owner);
            console.log("Title:", campaignDetails.title);
            console.log("Description:", campaignDetails.description);
            console.log("Target:", campaignDetails.target.toString());
            console.log("Deadline:", new Date(Number(campaignDetails.deadline) * 1000).toLocaleString());
            console.log("Amount Collected:", campaignDetails.amountCollected.toString());
            console.log("Image:", campaignDetails.image);
            console.log("Number of Donators:", campaignDetails.donators?.length);
        }

    } catch (error) {
        console.error("Error:", error);
    }
};

main().catch(console.error);

