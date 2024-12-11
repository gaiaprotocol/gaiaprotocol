import { ethers, network, upgrades } from "hardhat";
import "dotenv/config";

async function main() {
  const deployedProxyAddress = "0xc7B183c8544EbC389337af3Fd17A6DBb2D118816";

  const MaterialFactory = await ethers.getContractFactory("MaterialFactory");
  console.log("Upgrading MaterialFactory to", network.name);

  await upgrades.upgradeProxy(deployedProxyAddress, MaterialFactory);
  console.log("MaterialFactory upgraded");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
