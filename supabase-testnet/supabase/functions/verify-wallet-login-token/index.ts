import { verify } from "https://esm.sh/jsonwebtoken@8.5.1";
import { serve } from "https://raw.githubusercontent.com/yjgaia/deno-module/refs/heads/main/api.ts";

const JWT_SECRET = Deno.env.get("JWT_SECRET")!;

serve(async (req) => {
  const { token } = await req.json();
  if (!token) throw new Error("Missing token");

  // Verify the token using the secret
  const decoded = verify(token, JWT_SECRET) as
    | { wallet_address?: string }
    | undefined;
  if (!decoded?.wallet_address) throw new Error("Invalid token");

  return decoded.wallet_address;
});
