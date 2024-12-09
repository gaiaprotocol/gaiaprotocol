import { createPublicClient, http } from "https://esm.sh/viem@2.21.47";
import { base, baseSepolia } from "https://esm.sh/viem@2.21.47/chains";
import { serve } from "https://raw.githubusercontent.com/yjgaia/deno-module/refs/heads/main/api.ts";
import { safeStore } from "https://raw.githubusercontent.com/yjgaia/supabase-module/refs/heads/main/deno/supabase.ts";
import MaterialArtifact from "../_shared/artifacts/Material.json" with {
  type: "json",
};

const IS_TESTNET = true;

serve(async (req) => {
  const { address } = await req.json();
  if (!address) throw new Error("Invalid address");

  const client = createPublicClient({
    chain: IS_TESTNET ? baseSepolia : base,
    transport: http(),
  });

  const name = await client.readContract({
    address,
    abi: MaterialArtifact.abi,
    functionName: "name",
  });

  const symbol = await client.readContract({
    address,
    abi: MaterialArtifact.abi,
    functionName: "symbol",
  });

  await safeStore(
    "materials",
    (b) => b.update({ address, name, symbol }).eq("address", address),
  );
});
