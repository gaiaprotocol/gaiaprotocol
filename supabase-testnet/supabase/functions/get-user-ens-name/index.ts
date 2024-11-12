import { JsonRpcProvider } from "https://esm.sh/ethers@6.7.0";
import { serve } from "https://raw.githubusercontent.com/yjgaia/deno-module/refs/heads/main/api.ts";
import { extractWalletFromRequest } from "https://raw.githubusercontent.com/yjgaia/wallet-login-module/refs/heads/main/deno/auth.ts";

const INFURA_API_KEY = Deno.env.get("INFURA_API_KEY")!;

serve(async (req) => {
  const walletAddress = extractWalletFromRequest(req);
  const provider = new JsonRpcProvider(
    `https://mainnet.infura.io/v3/${INFURA_API_KEY}`,
  );
  return await provider.lookupAddress(walletAddress) ?? "";
});
