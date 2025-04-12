import { serve } from "https://raw.githubusercontent.com/yjgaia/deno-module/refs/heads/main/api.ts";
import {
  safeFetchSingle,
  safeStore,
} from "https://raw.githubusercontent.com/yjgaia/supabase-module/refs/heads/main/deno/supabase.ts";
import { extractWalletAddressFromRequest } from "https://raw.githubusercontent.com/yjgaia/wallet-login-module/refs/heads/main/deno/auth.ts";

serve(async (req) => {
  const walletAddress = await extractWalletAddressFromRequest(req);
  const { materialAddress, gameId } = await req.json();
  if (!materialAddress || !gameId) throw new Error("Invalid request");

  const game = await safeFetchSingle<{ owner: string }>(
    "games",
    (b) => b.select().eq("id", gameId),
  );

  if (!game) throw new Error("Invalid game_id");
  if (game.owner !== walletAddress) throw new Error("Unauthorized");

  const material = await safeFetchSingle<{ owner: string }>(
    "materials",
    (b) => b.select().eq("address", materialAddress).is("game_id", null),
  );

  if (!material) throw new Error("Invalid material_address");
  if (material.owner !== walletAddress) throw new Error("Unauthorized");

  await safeStore(
    "materials",
    (b) => b.update({ game_id: gameId }).eq("address", materialAddress),
  );
});
