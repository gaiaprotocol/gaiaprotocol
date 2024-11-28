import { ethers, network, upgrades } from "hardhat";
import "dotenv/config";

async function main() {
  const deployedProxyAddress = "0x9322C4A5E5725262C9960aDE87259d1cE2812412";

  const ClanEmblems = await ethers.getContractFactory("ClanEmblems");
  console.log("Upgrading ClanEmblems to", network.name);

  await upgrades.upgradeProxy(deployedProxyAddress, ClanEmblems);
  console.log("ClanEmblems upgraded");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
