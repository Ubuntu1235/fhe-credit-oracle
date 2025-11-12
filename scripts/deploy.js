const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // Deploy FHEVM
  const FHEVM = await ethers.getContractFactory("FHEVM");
  const fhevm = await FHEVM.deploy();
  await fhevm.waitForDeployment();
  console.log("FHEVM deployed to:", await fhevm.getAddress());

  // Deploy Credit Oracle
  const CreditOracle = await ethers.getContractFactory("FHECreditOracle");
  const creditOracle = await CreditOracle.deploy(await fhevm.getAddress());
  await creditOracle.waitForDeployment();
  console.log("CreditOracle deployed to:", await creditOracle.getAddress());

  // Allow credit oracle to use FHEVM
  await fhevm.allowContract(await creditOracle.getAddress());
  console.log("CreditOracle authorized on FHEVM");

  // Deploy Lending Pool
  const LendingPool = await ethers.getContractFactory("ConfidentialLendingPool");
  const lendingPool = await LendingPool.deploy(await creditOracle.getAddress());
  await lendingPool.waitForDeployment();
  console.log("LendingPool deployed to:", await lendingPool.getAddress());

  // Add lending pool to oracle
  const encryptedMinScore = ethers.toUtf8Bytes("700"); // Minimum score 700
  const encryptedMaxAmount = ethers.toUtf8Bytes("10000"); // Max loan $10,000
  await creditOracle.addLendingPool(
    await lendingPool.getAddress(),
    encryptedMinScore,
    encryptedMaxAmount,
    500 // 5% interest rate
  );
  console.log("Lending pool added to oracle");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });