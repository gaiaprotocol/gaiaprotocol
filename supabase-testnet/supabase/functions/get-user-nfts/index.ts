import { serve } from "https://raw.githubusercontent.com/yjgaia/deno-module/refs/heads/main/api.ts";
import { extractWalletAddressFromRequest } from "https://raw.githubusercontent.com/yjgaia/wallet-login-module/refs/heads/main/deno/auth.ts";

const OPENSEA_API_KEY = Deno.env.get("OPENSEA_API_KEY")!;

class APIError extends Error {
  constructor(public status: number, message: string) {
    super(message);
    this.name = "APIError";
  }
}

serve(async (req) => {
  const walletAddress = await extractWalletAddressFromRequest(req);
  const { next } = await req.json();

  const response = await fetch(
    `https://api.opensea.io/api/v2/chain/ethereum/account/${walletAddress}/nfts?limit=200${
      next ? `&next=${next}` : ""
    }`,
    { headers: { "X-API-KEY": OPENSEA_API_KEY } },
  );

  if (!response.ok) {
    const errorText = await response.text();
    throw new APIError(
      response.status,
      `OpenSea API error: ${errorText}`,
    );
  }

  return await response.json();
});
