import fs from "fs";
import path from "path";

const DESTINATIONS = {
  "token/GaiaProtocolToken": [
    "token-website/app/contracts/abi",
  ],
  "token/GaiaProtocolTokenTestnet": [
    "token-website/app/contracts/abi",
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
