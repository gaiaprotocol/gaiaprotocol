import "dotenv/config";
import { ethers, network, upgrades } from "hardhat";

async function main() {
  const deployedAddress = "0xa7727F706e1cbF6E5e7C38596067ab47A770cbB2";

  const PersonaFragments = await ethers.getContractFactory("PersonaFragments");
  console.log("Upgrading PersonaFragments to", network.name);

  await upgrades.upgradeProxy(deployedAddress, PersonaFragments);
  console.log("PersonaFragments upgraded");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
