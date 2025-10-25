const hre = require("hardhat");

async function main() {
  const TokenSmithy = await hre.ethers.getContractFactory("TokenSmithy");
  const token = await TokenSmithy.deploy();
  await token.waitForDeployment();

  console.log("TokenSmithy deployed to:", await token.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
