import { Material } from "../../../typechain-types/index.js";
import { MetamaskClient } from "hardhat_metamask_client";
import { config } from "chai";
import { ethers, network } from "hardhat";

const CONSTRUCTION_ADDRESS = "0xCb3428bA809B47d0cA7eC766d7d476986CF4fC10";
const TRAINING_ADDRESS = "0x87feE369B7Fd5766950447f6a8187Fb6bB4101e5";

const materialAddresses = {
  wood: "0xb1e50e052a2c5601BD92fddcc058ADDCFD44c6E7",
  stone: "0x63c45014DE5F0CbA76bbbA93A64D3d2DFd4f71cF",
  iron: "0x1605AE85E05B3E59Ae4728357DE39bAc81ed0277",
  ducat: "0x8D90c83bD9DBf0DB9D715378Bf4B7f3F5Ec749e5",
};

async function main() {
  const client = new MetamaskClient({
    hardhatConfig: config,
    networkName: network.name,
    network,
    ethers,
  });
  const signer = await client.getSigner();

  const Material = await ethers.getContractFactory("Material", signer);

  for (const [name, address] of Object.entries(materialAddresses)) {
    const contract = Material.attach(address) as Material;

    //const tx1 = await contract.addToWhitelist(CONSTRUCTION_ADDRESS);
    //await tx1.wait();

    const tx2 = await contract.addToWhitelist(TRAINING_ADDRESS);
    await tx2.wait();

    console.log(`Added Construction to whitelist of ${name}`);
  }

  console.log("Done!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
