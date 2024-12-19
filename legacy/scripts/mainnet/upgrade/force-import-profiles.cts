import { ethers, upgrades } from "hardhat";

async function main() {
  const proxyAdminAddress = "0x4720B04934c87388a7b9413413E2378EFF1D117C";
  const implAddress = "0xE59782E0c56ca3B5d8e6BBed0F6B8807978c7D0D";

  const ProxyAdminContract = await ethers.getContractFactory(
    "ProxyAdmin",
  );
  const Profiles = await ethers.getContractFactory(
    "Profiles",
  );

  console.log("Importing Profiles...");

  await upgrades.forceImport(proxyAdminAddress, ProxyAdminContract);
  await upgrades.forceImport(implAddress, Profiles);

  console.log("Profiles imported");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
