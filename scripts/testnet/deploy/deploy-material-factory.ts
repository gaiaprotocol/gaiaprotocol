import { ethers, network, upgrades } from "hardhat";

async function main() {
  const MaterialFactory = await ethers.getContractFactory("MaterialFactory");
  console.log("Deploying MaterialFactory to", network.name);

  const [account1] = await ethers.getSigners();

  const contract = await upgrades.deployProxy(
    MaterialFactory,
    [
      account1.address,
      25000000000000000n,
      25000000000000000n,
      100000000n,
    ],
    {
      initializer: "initialize",
      initialOwner: account1.address,
    },
  );
  await contract.waitForDeployment();

  console.log("MaterialFactory deployed to:", contract.target);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
