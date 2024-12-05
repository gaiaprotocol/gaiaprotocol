import { serve } from "https://raw.githubusercontent.com/yjgaia/deno-module/refs/heads/main/api.ts";
import { safeFetchSingle } from "https://raw.githubusercontent.com/yjgaia/supabase-module/refs/heads/main/deno/supabase.ts";
import { extractWalletAddressFromRequest } from "https://raw.githubusercontent.com/yjgaia/wallet-login-module/refs/heads/main/deno/auth.ts";

interface PendingClanData {
  name?: string;
  logo_image_url?: string;
  logo_thumbnail_url?: string;
  description?: string;
}

serve(async (req) => {
  extractWalletAddressFromRequest(req);

  const pendingClanData: PendingClanData = await req.json();

  pendingClanData.name = pendingClanData.name?.trim();
  if (!pendingClanData.name) throw new Error("Invalid name");
  if (pendingClanData.name.length > 100) throw new Error("Name is too long");

  if (
    pendingClanData.description && pendingClanData.description.length > 1000
  ) {
    throw new Error("Description is too long");
  }

  const data = await safeFetchSingle<{ metadata_hash: string }>(
    "pending_clans",
    (b) => b.insert(pendingClanData).select(),
  );

  return data?.metadata_hash;
});
