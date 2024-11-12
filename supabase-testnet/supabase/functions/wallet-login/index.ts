import { verifyMessage } from "https://esm.sh/ethers@6.7.0";
import { sign } from "https://esm.sh/jsonwebtoken@8.5.1";
import { SiweMessage } from "https://esm.sh/siwe@2.3.2";
import { serve } from "https://raw.githubusercontent.com/yjgaia/deno-module/refs/heads/main/api.ts";
import {
  safeFetchSingle,
  safeStore,
} from "https://raw.githubusercontent.com/yjgaia/supabase-module/refs/heads/main/deno/supabase.ts";

const MESSAGE_FOR_WALLET_LOGIN = Deno.env.get("MESSAGE_FOR_WALLET_LOGIN")!;
const JWT_SECRET = Deno.env.get("JWT_SECRET")!;

serve(async (req) => {
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

  const message = new SiweMessage({
    domain: data.domain,
    address: walletAddress,
    statement: MESSAGE_FOR_WALLET_LOGIN,
    uri: data.uri,
    version: "1",
    chainId: 1,
    nonce: data.nonce,
    issuedAt: data.issued_at,
  });

  // Verify the signed message
  const verifiedAddress = verifyMessage(
    message.prepareMessage(),
    signedMessage,
  );

  if (walletAddress !== verifiedAddress) throw new Error("Invalid signature");

  // Delete the used nonce to prevent replay attacks
  await safeStore(
    "wallet_login_nonces",
    (b) => b.delete().eq("wallet_address", walletAddress),
  );

  // Generate a JWT token for the authenticated user
  return sign({ wallet_address: walletAddress }, JWT_SECRET);
});
