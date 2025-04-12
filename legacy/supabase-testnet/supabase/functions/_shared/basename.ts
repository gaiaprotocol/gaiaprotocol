import {
  createPublicClient,
  encodePacked,
  getContract,
  http,
  keccak256,
  namehash,
} from "https://esm.sh/viem@2.21.47";
import { base } from "https://esm.sh/viem@2.21.47/chains";

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
  return cointype.toString(16).toUpperCase();
}

function convertReverseNodeToBytes(
  address: string,
  chainId: number,
): `0x${string}` {
  const addressFormatted = address.toLowerCase();
  const addressNode = keccak256(
    encodePacked(["string"], [addressFormatted.substring(2)]),
  );
  const chainCoinType = convertChainIdToCoinType(chainId);
  const baseReverseNode = namehash(`${chainCoinType}.reverse`);
  const addressReverseNode = keccak256(
    encodePacked(["bytes32", "bytes32"], [baseReverseNode, addressNode]),
  );
  return addressReverseNode;
}

// Create public client
const client = createPublicClient({
  chain: base,
  transport: http(),
});

// Create contract instance
const contract = getContract({
  address: BASENAME_L2_RESOLVER_ADDRESS,
  abi: ABI,
  client,
});

export async function getBasename(walletAddress: string): Promise<string> {
  const node = convertReverseNodeToBytes(walletAddress, 8453); // Base chainId
  const basename = await contract.read.name([node]) as string;
  return basename;
}
