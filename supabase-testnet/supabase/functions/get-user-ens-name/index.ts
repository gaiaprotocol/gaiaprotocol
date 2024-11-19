import { serve } from "https://raw.githubusercontent.com/yjgaia/deno-module/refs/heads/main/api.ts";
import { extractWalletAddressFromRequest } from "https://raw.githubusercontent.com/yjgaia/wallet-login-module/refs/heads/main/deno/auth.ts";

const INFURA_API_KEY = Deno.env.get("INFURA_API_KEY")!;

serve(async (req) => {
  const walletAddress = extractWalletAddressFromRequest(req);
  const provider = new JsonRpcProvider(
    `https://mainnet.infura.io/v3/${INFURA_API_KEY}`,
  );
  return await provider.lookupAddress(walletAddress) ?? "";
});
