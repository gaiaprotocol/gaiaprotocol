import fs from "fs";
import path from "path";

enum Env {
  APP = "app",
  DENO = "deno",
}

const APP_ETHERS_PATH = "ethers";
const APP_COMMON_PATH = "./common";
const DENO_ETHERS_PATH = "https://esm.sh/ethers@6.7.0";
const DENO_COMMON_PATH = "./common.ts";

const RELATIONS = {
  "gaming/MaterialTrade": {
    "gaiaprotocol-module/src/materialtech/contracts/abi": Env.APP,
  },
  "gaming/MaterialV1": {
    "gaiaprotocol-module/src/materialtech/contracts/abi": Env.APP,
  },
};

for (const [contract, relations] of Object.entries(RELATIONS)) {
  for (const [destination, env] of Object.entries(relations)) {
    const filename = path.basename(contract, path.extname(contract));
    const abiSource = fs.readFileSync(
      `../artifacts/contracts/${contract}.sol/${filename}.json`,
      "utf-8",
    );
    fs.writeFileSync(`../../${destination}/${filename}.json`, abiSource);

    const typeSource = fs.readFileSync(
      `../typechain-types/contracts/${contract}.ts`,
      "utf-8",
    );
    fs.writeFileSync(
      `../../${destination}/${filename}.ts`,
      typeSource.replace(
        `} from "ethers";`,
        `} from "${env === Env.APP ? APP_ETHERS_PATH : DENO_ETHERS_PATH}";`,
      ).replace(
        `} from "../../common";`,
        `} from "${env === Env.APP ? APP_COMMON_PATH : DENO_COMMON_PATH}";`,
      ),
    );
  }
}
