const hre = require("hardhat");
async function main() {
  const StashData = await hre.ethers.getContractFactory("ZephyrLiquidityStash");
  const stash = await StashData.deploy();
  await stash.deployed();
  console.log("Zephyr Liquidity Vault secured at:", stash.address);
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
