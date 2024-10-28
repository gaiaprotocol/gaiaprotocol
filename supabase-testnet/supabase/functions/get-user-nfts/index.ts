import { serve } from "https://raw.githubusercontent.com/yjgaia/deno-module/main/api.ts";
import { extractWalletFromRequest } from "../_shared/auth.ts";

const OPENSEA_API_KEY = Deno.env.get("OPENSEA_API_KEY")!;

class APIError extends Error {
  constructor(public status: number, message: string) {
    super(message);
    this.name = "APIError";
  }
}

serve(async (req) => {
  const walletAddress = extractWalletFromRequest(req);

  const response = await fetch(
    `https://api.opensea.io/api/v2/chain/ethereum/account/${walletAddress}/nfts?limit=200`,
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
