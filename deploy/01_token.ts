import { DeployFunction } from "hardhat-deploy/types";
import { LSP8Marketplace__factory } from "../types";
import { Ship } from "../utils";

const func: DeployFunction = async (hre) => {
  const { deploy } = await Ship.init(hre);
  const tx = await deploy(LSP8Marketplace__factory);
};

export default func;
func.tags = ["marketplace"];
