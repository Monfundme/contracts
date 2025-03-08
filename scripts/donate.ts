import { Contract, JsonRpcProvider, parseEther, Wallet } from "ethers";
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
        console.log("Start donation script...");
        // Get deployed campaigns
        const deployedCampaigns = await factory.getDeployedCampaigns();

        if (deployedCampaigns.length === 0) {
            console.log("No campaigns found");
            return;
        }

        // Get the first campaign for this example
        const campaignAddress = deployedCampaigns[0];
        const campaign = new Contract(campaignAddress, campaignArt.abi, wallet);

        console.log("Donating to campaign:", campaignAddress);

        // Donate 0.1 MON
        const donationAmount = parseEther("0.1");
        const donateTx = await campaign.donateWithMON({ value: donationAmount });
        await donateTx.wait();

        console.log("Successfully donated", donationAmount.toString(), "Mon to campaign!");
        console.log(donateTx.hash);

        // Get updated campaign details
        const campaignDetails = await campaign.campaign();
        console.log("Current amount collected:", campaignDetails.amountCollected.toString());

    } catch (error) {
        console.error("Error donating to campaign:", error);
    }
};

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
