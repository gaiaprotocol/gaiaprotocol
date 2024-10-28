import { Contract, JsonRpcProvider } from "https://esm.sh/ethers@6.7.0";
import { serve } from "https://raw.githubusercontent.com/yjgaia/deno-module/main/api.ts";
import { extractWalletFromRequest } from "../_shared/auth.ts";

const INFURA_API_KEY = Deno.env.get("INFURA_API_KEY")!;

const ENS_REVERSE_RECORDS = "0x3671aE578E63FdF66ad4F3E12CC0c0d71Ac7510C";
const ABI = [{
  "inputs": [{
    "internalType": "address[]",
    "name": "addresses",
    "type": "address[]",
  }],
  "name": "getNames",
  "outputs": [{ "internalType": "string[]", "name": "r", "type": "string[]" }],
  "stateMutability": "view",
  "type": "function",
}];

serve(async (req) => {
  const walletAddress = extractWalletFromRequest(req);
  const provider = new JsonRpcProvider(
    `https://mainnet.infura.io/v3/${INFURA_API_KEY}`,
  );
  const contract = new Contract(ENS_REVERSE_RECORDS, ABI, provider);
  const names = await contract.getNames([walletAddress]);
  return names.filter((name: string) => name !== "");
});
