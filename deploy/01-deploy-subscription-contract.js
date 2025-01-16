const { network } = require("hardhat");
const {
  networkConfig,
  developmentChains,
} = require("../helper-hardhat-config");
const { verify } = require("../utils/verify");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = network.chaidId;

  const multiCreatorSubscriptionService = await deploy(
    "MultiCreatorSubscriptionService",
    {
      from: deployer,
      args: [],
      log: true,
      waitConfirmations: network.config.blockConfirmations || 1,
    }
  );
  log(
    `...............${multiCreatorSubscriptionService.address}..............`
  );
  if (
    !developmentChains.includes(network.name) &&
    process.env.ETHERSCAN_API_KEY
  ) {
    await verify(multiCreatorSubscriptionService.address);
  }
};

module.exports.tags = ["all", "multiCreatorSubscriptionService"];
