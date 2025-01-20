import { serve } from "https://raw.githubusercontent.com/yjgaia/deno-module/refs/heads/main/api.ts";
import { safeFetchSingle } from "https://raw.githubusercontent.com/yjgaia/supabase-module/refs/heads/main/deno/supabase.ts";
import { extractWalletAddressFromRequest } from "https://raw.githubusercontent.com/yjgaia/wallet-login-module/refs/heads/main/deno/auth.ts";

interface PendingMaterialData {
  game_id?: number;
  logo_image_url?: string;
  logo_thumbnail_url?: string;
  description?: string;
}

serve(async (req) => {
  const walletAddress = await extractWalletAddressFromRequest(req);
  const pendingMaterialData: PendingMaterialData = await req.json();

  if (!pendingMaterialData.game_id) throw new Error("Invalid game_id");

  const game = await safeFetchSingle<{ owner: string }>(
    "games",
    (b) => b.select().eq("id", pendingMaterialData.game_id),
  );

  if (!game) throw new Error("Invalid game_id");
  if (game.owner !== walletAddress) throw new Error("Unauthorized");

  if (
    pendingMaterialData.description &&
    pendingMaterialData.description.length > 1000
  ) {
    throw new Error("Description is too long");
  }

  const data = await safeFetchSingle<{ metadata_hash: string }>(
    "pending_materials",
    (b) => b.insert(pendingMaterialData).select(),
  );

  return data?.metadata_hash;
});
