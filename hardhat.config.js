require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");


// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: "rinkeby",
  solidity: {
    compilers: [
      {
        version: "0.8.4",
      },
    ],
  },
  networks: {
    rinkeby: {
      url: "https://eth-rinkeby.alchemyapi.io/v2/DjQH9e4fD8Q4VbYMcC8oGXFbUEqPUH_v",
      accounts: ['fa662f47eeca7223323eaabe8fd228e1748e5ad1598a682d4e1d5aefdc728671'],
    },
    ropsten: {
      url: "https://eth-ropsten.alchemyapi.io/v2/ZuEYyKLqeVaumEL4MGRaYfBrFVVLNcAB",
      accounts: ['fa662f47eeca7223323eaabe8fd228e1748e5ad1598a682d4e1d5aefdc728671'],
    }
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: {
      ropsten: "CZQ8VJSA3XT9VA9XUWEXTR32W7BZEVPVE5"
    }
  }
};
