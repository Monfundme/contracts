import { Contract, Wallet, JsonRpcProvider } from "ethers";
import art from "../artifacts/contracts/MonfundmeFactory.sol/MonfundmeCampaign.json";
import dotenv from "dotenv";

dotenv.config();

const provider = new JsonRpcProvider(process.env.RPC_URL);
const wallet = new Wallet(process.env.PRIVATE_KEY as string, provider);
const contract = new Contract("0x06C2929357DA8910E8d064359532f2feA9e0BaBe", art.abi, wallet);

const withdraw = async () => {
    try {
        console.log("Withdrawing...");
        const tx = await contract.withdraw();
        const receipt = await tx.wait();
        console.log(receipt);

        // console.log(await contract.contractOwner());
    } catch (error) {
        console.log(error);
    }
}

withdraw();

