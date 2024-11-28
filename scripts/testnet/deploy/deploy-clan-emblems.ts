import { ethers, network, upgrades } from "hardhat";
import "dotenv/config";

async function main() {
  const ClanEmblems = await ethers.getContractFactory("ClanEmblems");
  console.log("Deploying ClanEmblems to", network.name);

  const [account1] = await ethers.getSigners();

  const contract = await upgrades.deployProxy(
    ClanEmblems,
    [
      account1.address,
      25000000000000000n,
      25000000000000000n,
      1000000000000000n,
      process.env.HOLDING_VERIFIER_ADDRESS,
    ],
    {
      initializer: "initialize",
      initialOwner: account1.address,
    },
  );
  await contract.waitForDeployment();

  console.log("ClanEmblems deployed to:", contract.target);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });