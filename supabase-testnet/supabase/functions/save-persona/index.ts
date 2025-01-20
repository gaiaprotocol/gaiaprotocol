import { serve } from "https://raw.githubusercontent.com/yjgaia/deno-module/refs/heads/main/api.ts";
import { safeStore } from "https://raw.githubusercontent.com/yjgaia/supabase-module/refs/heads/main/deno/supabase.ts";
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

serve(async (req) => {
  const walletAddress = await extractWalletAddressFromRequest(req);

  const personaData: PersonaEntity = await req.json();
  if (personaData.wallet_address !== walletAddress) {
    throw new Error("Invalid wallet address");
  }

  if (personaData.profile_nft_address && personaData.profile_nft_token_id) {
    const response = await fetch(
      `https://api.opensea.io/api/v2/chain/ethereum/contract/${personaData.profile_nft_address}/nfts/${personaData.profile_nft_token_id}`,
      { headers: { "X-API-KEY": OPENSEA_API_KEY } },
    );

    if (!response.ok) {
      const errorText = await response.text();
      throw new APIError(
        response.status,
        `OpenSea API error: ${errorText}`,
      );
    } else if (
      personaData.profile_nft_address || personaData.profile_nft_token_id
    ) {
      throw new Error("Invalid NFT ownership");
    }

    const result = await response.json();
    if (
      !result.nft.owners.some((owner: any) => owner.address === walletAddress)
    ) {
      throw new Error("Invalid NFT ownership");
    }
  }

  personaData.name = personaData.name?.trim();
  if (personaData.name) {
    if (personaData.is_ens_name) {
      const ensName = await getEnsName(walletAddress);
      if (ensName !== personaData.name) throw new Error("Invalid ENS name");
    } else if (personaData.is_basename) {
      const basename = await getBasename(walletAddress);
      if (basename !== personaData.name) throw new Error("Invalid basename");
    } else if (personaData.is_gaia_name) {
      const gaiaName = await getGaiaName(walletAddress);
      if (gaiaName !== personaData.name) throw new Error("Invalid Gaia name");
    } else {
      if (personaData.name.length > 100) throw new Error("Name is too long");
      //if (!isValidName(personaData.name)) throw new Error("Invalid name");
      if (personaData.name.includes(".")) {
        throw new Error("Name cannot contain periods");
      }
    }
  }

  if (personaData.bio && personaData.bio.length > 1000) {
    throw new Error("Bio is too long");
  }

  await safeStore(
    "personas",
    (b) => b.upsert(personaData),
  );
});
