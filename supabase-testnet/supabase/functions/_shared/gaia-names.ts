import { createClient } from "https://esm.sh/@supabase/supabase-js@2.31.0";

const godModeSupabase = createClient(
  "https://dhzxulywizygtdficytt.supabase.co",
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRoenh1bHl3aXp5Z3RkZmljeXR0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzAxMTIxNDUsImV4cCI6MjA0NTY4ODE0NX0.xUd8nqcT2aVn1j4x8c-pRbDcFSaIGtkn7SAcmKleBms",
);

export async function getGaiaName(
  walletAddress: `0x${string}`,
): Promise<string> {
  const { data: gaiaNameData, error } = await godModeSupabase.from(
    "gaia_names",
  ).select("*").eq("wallet_address", walletAddress).maybeSingle();
  if (error) throw error;
  return gaiaNameData?.name ? `${gaiaNameData.name}.gaia` : "";
}
