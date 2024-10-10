import { config } from "chai";
import { ethers, network } from "hardhat";
import { MetamaskClient } from "hardhat_metamask_client";

async function main() {
  const client = new MetamaskClient({
    hardhatConfig: config,
    networkName: network.name,
    network,
    ethers,
  });
  const signer = await client.getSigner();

  console.log("Deploying MaterialTrade to ", network.name);

  // Deploy ProxyAdmin and set its owner
  const ProxyAdmin = await ethers.getContractFactory("ProxyAdmin", signer);
  const proxyAdmin = await ProxyAdmin.deploy();
  await proxyAdmin.waitForDeployment();
  console.log("ProxyAdmin deployed to:", proxyAdmin.target);

  // Deploy the implementation contract
  const MaterialTrade = await ethers.getContractFactory(
    "MaterialTrade",
    signer,
  );
  const impl = await MaterialTrade.deploy();
  await impl.waitForDeployment();
  console.log(
    "MaterialTrade implementation deployed to:",
    impl.target,
  );

  // Deploy TransparentUpgradeableProxy
  const TransparentUpgradeableProxy = await ethers.getContractFactory(
    "TransparentUpgradeableProxy",
    signer,
  );
  const initData = MaterialTrade.interface.encodeFunctionData(
    "initialize",
    [
      "0x48674148a4043EAadB92E5D8D7C493121D6489b1",
      50000000000000000n,
      50000000000000000n,
      10000000000000000000000000000000n,
      10000000000000000000000000000000n,
    ],
  );
  const proxy = await TransparentUpgradeableProxy.deploy(
    impl.target,
    proxyAdmin.target,
    initData,
  );

  console.log(
    impl.target,
    proxyAdmin.target,
    initData,
  );

  await proxy.waitForDeployment();

  console.log("MaterialTrade proxy deployed to:", proxy.target);

  client.close();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
