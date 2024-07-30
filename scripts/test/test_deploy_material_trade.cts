const { ethers, network, upgrades } = require("hardhat");

async function main() {
  const MaterialTrade = await ethers.getContractFactory("MaterialTrade");
  console.log("Deploying MaterialTrade to ", network.name);

  const [account1] = await ethers.getSigners();

  const contract = await upgrades.deployProxy(
    MaterialTrade,
    [
      16000n * 10000n, //IMPORTANT! base divider
      account1.address,
      BigInt("50000000000000000"),
      BigInt("50000000000000000"),
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
