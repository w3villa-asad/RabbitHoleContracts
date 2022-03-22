// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  await hre.run('compile');

  // We get the contract to deploy
  const RabbitHoleNFTToken = await hre.ethers.getContractFactory("RabbitHoleNFTToken");
  const rabbitHoleNFTToken = await RabbitHoleNFTToken.deploy();
  await rabbitHoleNFTToken.deployed();
  console.log("RabbitHoleNFTToken deployed to:", rabbitHoleNFTToken.address);

  const RabbitHoleToken = await hre.ethers.getContractFactory("RabbitHoleToken");
  const rabbitHoleToken = await RabbitHoleToken.deploy();
  await rabbitHoleToken.deployed();
  console.log("RabbitHoleToken deployed to:", rabbitHoleToken.address);


  // TODO: Change for mainnet
  const swapRouter = "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45";
  const adminAddress = "0x3F5fE04Af03dc015aDaCfaC8198a8E46df056fF1";
  const RabbitHoleSwapperTestnet = await hre.ethers.getContractFactory("RabbitHoleSwapperTestnet");
  const rabbitHoleSwapperTestnet = await RabbitHoleSwapperTestnet.deploy(swapRouter, rabbitHoleToken.address, adminAddress);
  await rabbitHoleSwapperTestnet.deployed();
  console.log("RabbitHoleSwapperTestnet deployed to:", rabbitHoleSwapperTestnet.address);

  await hre.run("verify:verify", {
    address: rabbitHoleNFTToken.address,
  });

  await hre.run("verify:verify", {
    address: rabbitHoleToken.address,
  });

  await hre.run("verify:verify", {
    address: rabbitHoleSwapperTestnet.address,
    constructorArguments: [
      swapRouter,
      rabbitHoleToken.address,
      adminAddress,
    ],
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
