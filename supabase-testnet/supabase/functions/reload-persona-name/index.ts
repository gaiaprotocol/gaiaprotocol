import { createClient } from "https://esm.sh/@supabase/supabase-js@2.31.0";
import { serve } from "https://raw.githubusercontent.com/yjgaia/deno-module/refs/heads/main/api.ts";
import {
  safeFetchSingle,
  safeStore,
} from "https://raw.githubusercontent.com/yjgaia/supabase-module/refs/heads/main/deno/supabase.ts";
import { extractWalletAddressFromRequest } from "https://raw.githubusercontent.com/yjgaia/wallet-login-module/refs/heads/main/deno/auth.ts";
import { getBasename } from "../_shared/basename.ts";
import { getEnsName } from "../_shared/ens.ts";
import { getGaiaName } from "../_shared/gaia-names.ts";

interface PersonaEntity {
  wallet_address: string;

  name?: string;
  is_ens_name?: boolean;
  is_basename?: boolean;
  is_gaia_name?: boolean;

  profile_image_url?: string;
  profile_thumbnail_url?: string;
  profile_nft_address?: string;
  profile_nft_token_id?: string;

  bio?: string;
}

const OPENSEA_API_KEY = Deno.env.get("OPENSEA_API_KEY")!;

class APIError extends Error {
  constructor(public status: number, message: string) {
    super(message);
    this.name = "APIError";
  }
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

  const personaData = await safeFetchSingle<PersonaEntity>(
    "personas",
    (b) => b.select("*").eq("wallet_address", walletAddress),
  );

  if (!personaData) throw new Error("Persona not found");

  let name: string | undefined | null = personaData.name;
  if (name) {
    if (personaData.is_ens_name) {
      const ensName = await getEnsName(walletAddress);
      if (ensName !== name) name = ensName;
    } else if (personaData.is_basename) {
      const basename = await getBasename(walletAddress);
      if (basename !== name) name = basename;
    } else if (personaData.is_gaia_name) {
      const gaiaName = await getGaiaName(walletAddress);
      if (gaiaName !== name) name = gaiaName;
    }
    if (name.trim() === "") name = undefined;
  }

  if (name === undefined) name = null;

  await safeStore(
    "personas",
    (b) => b.update({ name }).eq("wallet_address", walletAddress),
  );
});
