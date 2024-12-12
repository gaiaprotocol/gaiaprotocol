import { ethers, network, upgrades } from "hardhat";
import "dotenv/config";

async function main() {
  const deployedProxyAddress = "0x5A131Af55290f9796024C33e548E14FDc73F7F5D";

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
