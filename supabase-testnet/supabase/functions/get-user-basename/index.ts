import {
  Contract,
  JsonRpcProvider,
  namehash,
  solidityPackedKeccak256,
} from "https://esm.sh/ethers@6.7.0";
import { serve } from "https://raw.githubusercontent.com/yjgaia/deno-module/refs/heads/main/api.ts";
import { extractWalletFromRequest } from "https://raw.githubusercontent.com/yjgaia/wallet-login-module/refs/heads/main/deno/auth.ts";

const BASENAME_L2_RESOLVER_ADDRESS =
  "0xC6d566A56A1aFf6508b41f6c90ff131615583BCD";
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

function convertChainIdToCoinType(chainId: number): string {
  if (chainId === 1) return "addr";
  const cointype = (0x80000000 | chainId) >>> 0;
  return cointype.toString(16).toLocaleUpperCase();
}

function convertReverseNodeToBytes(address: string, chainId: number): string {
  const addressFormatted = address.toLowerCase();
  const addressNode = solidityPackedKeccak256(["string"], [
    addressFormatted.substring(2),
  ]);
  const chainCoinType = convertChainIdToCoinType(chainId);
  const baseReverseNode = namehash(`${chainCoinType}.reverse`);
  const addressReverseNode = solidityPackedKeccak256(["bytes32", "bytes32"], [
    baseReverseNode,
    addressNode,
  ]);
  return addressReverseNode;
}

serve(async (req) => {
  const walletAddress = extractWalletFromRequest(req);
  const provider = new JsonRpcProvider("https://mainnet.base.org");
  const contract = new Contract(BASENAME_L2_RESOLVER_ADDRESS, ABI, provider);
  const node = convertReverseNodeToBytes(walletAddress, 8453); // Base chainId
  const basename = await contract.name(node);
  return basename;
});
