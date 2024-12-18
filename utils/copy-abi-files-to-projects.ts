import fs from "fs";
import path from "path";

const DESTINATIONS = {
  "token/GaiaProtocolToken": [
    "token-website/app/contracts/artifacts",
  ],
  "token/GaiaProtocolTokenTestnet": [
    "token-website/app/contracts/artifacts",
  ],
  "social/PersonaFragments": [
    "gaiaprotocol/supabase-testnet/supabase/functions/_shared/artifacts",
    "gaiaprotocol-module/src/persona/contracts/artifacts",
  ],
  "social/ClanEmblems": [
    "gaiaprotocol/supabase-testnet/supabase/functions/_shared/artifacts",
    "gaiaprotocol-module/src/clan/contracts/artifacts",
  ],
  "social/TopicShares": [
    "gaiaprotocol/supabase-testnet/supabase/functions/_shared/artifacts",
    "gaiaprotocol-module/src/topic/contracts/artifacts",
  ],
  "gaming/Material": [
    "gaiaprotocol/supabase-testnet/supabase/functions/_shared/artifacts",
    "gaiaprotocol-module/src/material/contracts/artifacts",
  ],
  "gaming/MaterialFactory": [
    "gaiaprotocol/supabase-testnet/supabase/functions/_shared/artifacts",
    "gaiaprotocol-module/src/material/contracts/artifacts",
  ],
};

for (const [contract, destinations] of Object.entries(DESTINATIONS)) {
  for (const destination of destinations) {
    const filename = path.basename(contract, path.extname(contract));
    const abiSource = fs.readFileSync(
      `../artifacts/contracts/${contract}.sol/${filename}.json`,
      "utf-8",
    );
    fs.writeFileSync(`../../${destination}/${filename}.json`, abiSource);
  }
}
