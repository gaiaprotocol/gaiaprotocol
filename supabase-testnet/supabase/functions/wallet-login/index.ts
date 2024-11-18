import { sign } from "https://esm.sh/jsonwebtoken@8.5.1";
import { verifyMessage } from "https://esm.sh/viem@2.21.47";
import { createSiweMessage } from "https://esm.sh/viem@2.21.47/siwe";
import { serve } from "https://raw.githubusercontent.com/yjgaia/deno-module/refs/heads/main/api.ts";
import {
  safeFetchSingle,
  safeStore,
} from "https://raw.githubusercontent.com/yjgaia/supabase-module/refs/heads/main/deno/supabase.ts";

const MESSAGE_FOR_WALLET_LOGIN = Deno.env.get("MESSAGE_FOR_WALLET_LOGIN")!;
const JWT_SECRET = Deno.env.get("JWT_SECRET")!;

serve(async (req, ip) => {
  const { walletAddress, signedMessage } = await req.json();
  if (!walletAddress || !signedMessage) throw new Error("Missing parameters");

  // Retrieve the nonce associated with the wallet address
  const data = await safeFetchSingle<
    { nonce: string; domain: string; uri: string; issued_at: string }
  >(
    "wallet_login_nonces",
    (b) => b.select().eq("wallet_address", walletAddress),
  );

  if (!data) throw new Error("Invalid wallet address");

  const message = createSiweMessage({
    domain: data.domain,
    address: walletAddress,
    statement: MESSAGE_FOR_WALLET_LOGIN,
    uri: data.uri,
    version: "1",
    chainId: 1,
    nonce: data.nonce,
    issuedAt: new Date(data.issued_at),
  });

  // Verify the signed message
  const verified = await verifyMessage({
    address: walletAddress,
    message,
    signature: signedMessage,
  });
  if (!verified) throw new Error("Invalid signature");

  // Delete the used nonce to prevent replay attacks
  await safeStore(
    "wallet_login_nonces",
    (b) => b.delete().eq("wallet_address", walletAddress),
  );

  await safeStore(
    "user_sessions",
    (b) =>
      b.insert({
        wallet_address: walletAddress,
        ip,
        real_ip: req.headers.get("x-real-ip"),
        forwarded_for: req.headers.get("x-forwarded-for"),
        user_agent: req.headers.get("user-agent"),
        origin: req.headers.get("origin"),
        referer: req.headers.get("referer"),
        accept_language: req.headers.get("accept-language"),
      }),
  );

  // Generate a JWT token for the authenticated user
  return sign({ wallet_address: walletAddress }, JWT_SECRET);
});
