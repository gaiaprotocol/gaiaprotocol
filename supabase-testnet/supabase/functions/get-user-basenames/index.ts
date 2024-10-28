import {
  Contract,
  JsonRpcProvider,
  namehash,
} from "https://esm.sh/ethers@6.7.0";
import { serve } from "https://raw.githubusercontent.com/yjgaia/deno-module/main/api.ts";
import { extractWalletFromRequest } from "../_shared/auth.ts";

const BASENAMES_REVERSE_RECORDS = "0xC6d566A56A1aFf6508b41f6c90ff131615583BCD";
const ABI = [{
  "inputs": [{
    "internalType": "bytes32",
    "name": "node",
    "type": "bytes32",
  }],
  "name": "name",
  "outputs": [{
    "internalType": "string",
    "name": "",
    "type": "string",
  }],
  "stateMutability": "view",
  "type": "function",
}];

serve(async (req) => {
  const walletAddress = extractWalletFromRequest(req);
  const provider = new JsonRpcProvider("https://mainnet.base.org");
  const contract = new Contract(BASENAMES_REVERSE_RECORDS, ABI, provider);
  const addr = walletAddress.toLowerCase().replace("0x", "");
  const baseNameNode = namehash(`${addr}.addr.reverse`);
  return await contract.name(baseNameNode);
});
