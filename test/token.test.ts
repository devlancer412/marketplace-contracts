import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { LSP8Marketplace, LSP8Marketplace__factory } from "../types";
import { deployments } from "hardhat";
import chai from "chai";
import { solidity } from "ethereum-waffle";
import { Ship } from "../utils";
import { parseEther } from "ethers/lib/utils";

chai.use(solidity);
const { expect } = chai;

let ship: Ship;
let marketplace: LSP8Marketplace;
let alice: SignerWithAddress;
let bob: SignerWithAddress;
let signer: SignerWithAddress;
let deployer: SignerWithAddress;

const setup = deployments.createFixture(async (hre) => {
  ship = await Ship.init(hre);
  const { accounts, users } = ship;
  await deployments.fixture(["token"]);

  return {
    ship,
    accounts,
    users,
  };
});

describe("Pegged Palladium test", () => {
  before(async () => {
    const scaffold = await setup();

    alice = scaffold.accounts.alice;
    bob = scaffold.accounts.bob;
    deployer = scaffold.accounts.deployer;
    signer = scaffold.accounts.signer;

    marketplace = await scaffold.ship.connect(LSP8Marketplace__factory);
  });
});
