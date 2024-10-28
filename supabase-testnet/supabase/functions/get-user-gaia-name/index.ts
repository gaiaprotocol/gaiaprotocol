import { serve } from "https://raw.githubusercontent.com/yjgaia/deno-module/main/api.ts";
import { extractWalletFromRequest } from "../_shared/auth.ts";

serve(async (req) => {
  const walletAddress = extractWalletFromRequest(req);

  throw new Error("Not implemented");
});
