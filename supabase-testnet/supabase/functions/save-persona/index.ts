import { createClient } from "https://esm.sh/@supabase/supabase-js@2.31.0";
import { serve } from "https://raw.githubusercontent.com/yjgaia/deno-module/refs/heads/main/api.ts";
import { safeStore } from "https://raw.githubusercontent.com/yjgaia/supabase-module/refs/heads/main/deno/supabase.ts";
import { extractWalletAddressFromRequest } from "https://raw.githubusercontent.com/yjgaia/wallet-login-module/refs/heads/main/deno/auth.ts";
import { getBasename } from "../_shared/basename.ts";
import { getEnsName } from "../_shared/ens.ts";

interface PersonaEntity {
  wallet_address: string;

  name?: string;
  is_ens_name?: boolean;
  is_basename?: boolean;
  is_gaia_name?: boolean;

  profile_image_url?: string;
  thumbnail_image_url?: string;

  nft_address?: string;
  nft_token_id?: string;

  bio?: string;
  social_links?: string[];
}

function isValidName(name: string): boolean {
  if (!name) return false;
  if (!/^[a-z0-9-]+$/.test(name)) return false;
  if (name.startsWith("-") || name.endsWith("-")) return false;
  if (name.includes("--")) return false;
  if (name !== name.normalize("NFC")) return false;
  return true;
}

const godModeSupabase = createClient(
  "https://dhzxulywizygtdficytt.supabase.co",
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRoenh1bHl3aXp5Z3RkZmljeXR0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzAxMTIxNDUsImV4cCI6MjA0NTY4ODE0NX0.xUd8nqcT2aVn1j4x8c-pRbDcFSaIGtkn7SAcmKleBms",
);

serve(async (req) => {
  const walletAddress = extractWalletAddressFromRequest(req);

  const personaData: PersonaEntity = await req.json();
  if (personaData.wallet_address !== walletAddress) {
    throw new Error("Invalid wallet address");
  }

  personaData.name = personaData.name?.trim();
  if (!personaData.name) throw new Error("Missing required parameters");
  if (personaData.name.length > 100) throw new Error("Name is too long");
  if (!isValidName(personaData.name)) throw new Error("Invalid name");
  if (personaData.name.includes(".")) {
    throw new Error("Name cannot contain periods");
  }

  if (personaData.is_ens_name) {
    const ensName = await getEnsName(walletAddress);
    if (ensName !== personaData.name) throw new Error("Invalid ENS name");
  }

  if (personaData.is_basename) {
    const basename = await getBasename(walletAddress);
    if (basename !== personaData.name) throw new Error("Invalid basename");
  }

  if (personaData.is_gaia_name) {
    const { data: gaiaNameData, error } = await godModeSupabase.from(
      "gaia_names",
    ).select("*").eq("name", personaData.name).single();
    if (error) throw error;

    if (!gaiaNameData) throw new Error("Gaia name not found");
    if (gaiaNameData.wallet_address !== walletAddress) {
      throw new Error("Invalid wallet address");
    }
  }

  if (personaData.bio && personaData.bio.length > 1000) {
    throw new Error("Bio is too long");
  }

  if (
    personaData.social_links &&
    personaData.social_links.every((link) => link.length > 256)
  ) {
    throw new Error("Social link is too long");
  }

  await safeStore(
    "personas",
    (b) => b.upsert(personaData),
  );
});
