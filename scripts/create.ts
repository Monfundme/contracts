
import { monfundme_factory } from "../contstants";
import { Contract, JsonRpcProvider, keccak256, parseEther, randomBytes, toUtf8Bytes, Wallet, } from "ethers";
import factoryAbi from "../artifacts/contracts/MonfundmeFactory.sol/MonfundmeFactory.json";
import dotenv from "dotenv";

dotenv.config();

async function main() {

    const provider = new JsonRpcProvider(process.env.RPC_URL);
    const wallet = new Wallet(process.env.v_1 as string, provider);

    const factory = new Contract(monfundme_factory, factoryAbi.abi, wallet);

    // Campaign parameters
    const campaignId = randomBytes(100); // Generate random 12 byte ID
    const campaignOwner = wallet.address;
    const metadataHash = keccak256(toUtf8Bytes("Test Campaign")); // Example metadata hash
    const target = parseEther("1.4"); // 1 MON target
    const deadline = Math.floor(Date.now() / 1000) + 86400; // 24 hours from now

    try {

        const tx = await factory.createCampaign(
            campaignId,
            campaignOwner,
            metadataHash,
            target,
            deadline
        );

        const receipt = await tx.wait();

        console.log("Campaign created at:", receipt.hash);


    } catch (error) {
        console.error("Error creating campaign:", error);
    }
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

