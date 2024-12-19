import { ethers, network } from "hardhat";

async function main() {
  const GaiaProtocolTokenTestnet = await ethers.getContractFactory(
    "GaiaProtocolTokenTestnet",
  );
  console.log("Deploying GaiaProtocolTokenTestnet to:", network.name);

  const contract = await GaiaProtocolTokenTestnet.deploy();
  await contract.waitForDeployment();

  console.log("GaiaProtocolTokenTestnet deployed to:", contract.target);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
