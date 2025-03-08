import "@nomicfoundation/hardhat-verify";
import { HardhatUserConfig } from "hardhat/config";
import * as dotenv from "dotenv";

dotenv.config();

const config: HardhatUserConfig = {
	solidity: {
		version: "0.8.24",
		settings: {
			metadata: {
				bytecodeHash: "none", // disable ipfs
				useLiteralContent: true // use source code
			},
			optimizer: {
				enabled: true,
				runs: 200
			}
		}
	},
	networks: {
		monadTestnet: {
			url: "https://testnet-rpc.monad.xyz",
			chainId: 10143,
		},
	},
	sourcify: {
		enabled: true,
		apiUrl: "https://sourcify-api-monad.blockvision.org",
		browserUrl: "https://testnet.monadexplorer.com"
	},
	etherscan: { enabled: false }
};

export default config;