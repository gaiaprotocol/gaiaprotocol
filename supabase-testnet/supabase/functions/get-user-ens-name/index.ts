import { serve } from "https://raw.githubusercontent.com/yjgaia/deno-module/refs/heads/main/api.ts";
import { extractWalletAddressFromRequest } from "https://raw.githubusercontent.com/yjgaia/wallet-login-module/refs/heads/main/deno/auth.ts";
import { getEnsName } from "../_shared/ens.ts";

serve(async (req) => {
  const walletAddress = extractWalletAddressFromRequest(req);
  return await getEnsName(walletAddress);
});
