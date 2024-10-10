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

  console.log("Deploying Profiles to ", network.name);

  // Deploy ProxyAdmin and set its owner
  const ProxyAdmin = await ethers.getContractFactory("ProxyAdmin", signer);
  const proxyAdmin = await ProxyAdmin.deploy();
  await proxyAdmin.waitForDeployment();
  console.log("ProxyAdmin deployed to:", proxyAdmin.target);

  // Deploy the implementation contract
  const Profiles = await ethers.getContractFactory(
    "Profiles",
    signer,
  );
  const impl = await Profiles.deploy();
  await impl.waitForDeployment();
  console.log(
    "Profiles implementation deployed to:",
    impl.target,
  );

  // Deploy TransparentUpgradeableProxy
  const TransparentUpgradeableProxy = await ethers.getContractFactory(
    "TransparentUpgradeableProxy",
    signer,
  );
  const initData = Profiles.interface.encodeFunctionData(
    "initialize",
    [],
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

  console.log("Profiles proxy deployed to:", proxy.target);

  client.close();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
