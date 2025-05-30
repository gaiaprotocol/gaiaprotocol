import { create } from "https://deno.land/x/djwt@v3.0.1/mod.ts";
import { getAddress, verifyMessage } from "https://esm.sh/viem@2.21.47";
import { createSiweMessage } from "https://esm.sh/viem@2.21.47/siwe";
import { serve } from "https://raw.githubusercontent.com/yjgaia/deno-module/refs/heads/main/api.ts";
import {
  safeFetchSingle,
  safeStore,
} from "https://raw.githubusercontent.com/yjgaia/supabase-module/refs/heads/main/deno/supabase.ts";

const MESSAGE_FOR_WALLET_LOGIN = Deno.env.get("MESSAGE_FOR_WALLET_LOGIN")!;
const JWT_SECRET = Deno.env.get("JWT_SECRET")!;

const key = await crypto.subtle.importKey(
  "raw",
  new TextEncoder().encode(JWT_SECRET),
  { name: "HMAC", hash: "SHA-256" },
  false,
  ["sign"],
);

serve(async (req, ip) => {
  let { walletAddress, signedMessage } = await req.json();
  if (!walletAddress || !signedMessage) throw new Error("Missing parameters");

  walletAddress = getAddress(walletAddress);

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

  // Generate a JWT token for the authenticated user
  const token = await create(
    { alg: "HS256", typ: "JWT" },
    { wallet_address: walletAddress },
    key,
  );

  await safeStore(
    "user_sessions",
    (b) =>
      b.insert({
        wallet_address: walletAddress,
        token,
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
  return token;
});
