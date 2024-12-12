import { ethers, network, upgrades } from "hardhat";
import "dotenv/config";

async function main() {
  const deployedProxyAddress = "0x8A89D79282577E78968eECF6a9d5fC1B5FE58AbD";

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
