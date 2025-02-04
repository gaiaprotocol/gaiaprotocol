import "dotenv/config";
import { ethers, network, upgrades } from "hardhat";

async function main() {
  const deployedAddress = "0x9EF42F082360c606d3D0480404F47924323B4D8b";

  const MaterialFactory = await ethers.getContractFactory("MaterialFactory");
  console.log("Upgrading MaterialFactory to", network.name);

  await upgrades.upgradeProxy(deployedAddress, MaterialFactory);
  console.log("MaterialFactory upgraded");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
