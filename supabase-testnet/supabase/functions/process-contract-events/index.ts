import { serve } from "https://raw.githubusercontent.com/yjgaia/deno-module/refs/heads/main/api.ts";
import { getChainById } from "https://raw.githubusercontent.com/yjgaia/wallet-utils/refs/heads/main/deno/mod.ts";

serve(async (req) => {
  let { chainId, contractAddress, blockPeriod } = await req.json();
  if (!chainId || !contractAddress) {
    throw new Error("Missing chainId or contractAddress");
  }

  if (!blockPeriod) {
    // base
    if (chainId === 8453 || chainId === 84532) blockPeriod = 500;
    // arbitrum
    else if (chainId === 42161 || chainId === 421614) blockPeriod = 2500;
    // else
    else blockPeriod = 750;
  }
});
