import { config } from "chai";
import { ethers, network } from "hardhat";
import { MetamaskClient } from "hardhat_metamask_client";

const { upgrades } = require("hardhat");

async function main() {
  const deployedProxyAddress = process.env.PROFILES_ADDRESS!;

  const client = new MetamaskClient({
    hardhatConfig: config,
    networkName: network.name,
    network,
    ethers,
  });

  const signer = await client.getSigner();
  const Profiles = await ethers.getContractFactory(
    "Profiles",
    signer,
  );
  console.log("Upgrading Profiles...");

  await upgrades.upgradeProxy(deployedProxyAddress, Profiles);
  console.log("Profiles upgraded");

  client.close();
  process.exit();
}

main();
