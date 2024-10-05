const { ethers, network, upgrades } = require("hardhat");

async function main() {
  const MaterialTrade = await ethers.getContractFactory("MaterialTrade");
  console.log("Deploying MaterialTrade to ", network.name);

  const [account1] = await ethers.getSigners();

  const contract = await upgrades.deployProxy(
    MaterialTrade,
    [
      account1.address,
      25000000000000000n,
      25000000000000000n,
      1000000000000000n,
    ],
    {
      initializer: "initialize",
      initialOwner: account1.address,
    },
  );
  await contract.waitForDeployment();

  console.log("MaterialTrade deployed to:", contract.target);

  process.exit();
}

main();
