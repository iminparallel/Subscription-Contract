const { assert, expect, chai } = require("chai");
const { network, deployments, ethers } = require("hardhat");
const { developmentChains } = require("../../helper-hardhat-config");

!developmentChains.includes(network.name)
  ? describe.skip
  : describe("MultiCreatorSubscriptionService", function () {
      let deployer;
      let multiCreatorSubscriptionService;
      beforeEach(async () => {
        deployer = (await getNamedAccounts()).deployer;
        await deployments.fixture(["all"]);

        const multiCreatorSubscriptionServiceDeployment = await deployments.get(
          "MultiCreatorSubscriptionService"
        );
        multiCreatorSubscriptionService = await ethers.getContractAt(
          "MultiCreatorSubscriptionService",
          multiCreatorSubscriptionServiceDeployment.address
        );
      });

      describe("constructor", function () {
        it("sets the owner correctly", async () => {
          const owner = await multiCreatorSubscriptionService.s_owner();
          assert.equal(owner, deployer);
        });
      });

      describe("createProduct", function () {});
    });
