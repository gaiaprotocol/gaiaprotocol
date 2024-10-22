import { serve } from "https://raw.githubusercontent.com/yjgaia/deno-module/main/api.ts";
import {
  safeFetchSingle,
  safeStore,
} from "https://raw.githubusercontent.com/yjgaia/supabase-module/main/deno/supabase.ts";

serve(async (req) => {
  const { walletAddress } = await req.json();
  if (!walletAddress) throw new Error("Missing wallet address");

  // Delete any existing nonce for this wallet address
  await safeStore(
    "wallet_login_nonces",
    (b) => b.delete().eq("wallet_address", walletAddress),
  );

  // Generate a new nonce and insert it into the database
  const data = await safeFetchSingle<{ nonce: string }>(
    "wallet_login_nonces",
    (b) => b.insert({ wallet_address: walletAddress }).select(),
  );

  return data!.nonce;
});
