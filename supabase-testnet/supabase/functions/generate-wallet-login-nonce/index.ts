import { serve } from "https://raw.githubusercontent.com/yjgaia/deno-module/refs/heads/main/api.ts";
import {
  safeFetchSingle,
  safeStore,
} from "https://raw.githubusercontent.com/yjgaia/supabase-module/refs/heads/main/deno/supabase.ts";

serve(async (req) => {
  const { walletAddress, domain, uri } = await req.json();
  if (!walletAddress || !domain || !uri) {
    throw new Error("Missing required parameters");
  }

  // Delete any existing nonce for this wallet address
  await safeStore(
    "wallet_login_nonces",
    (b) => b.delete().eq("wallet_address", walletAddress),
  );

  // Generate a new nonce and insert it into the database
  const data = await safeFetchSingle<{ nonce: string; issued_at: string }>(
    "wallet_login_nonces",
    (b) => b.insert({ wallet_address: walletAddress, domain, uri }).select(),
  );

  return { nonce: data!.nonce, issuedAt: data!.issued_at };
});
