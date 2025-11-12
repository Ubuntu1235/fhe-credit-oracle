const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts to Sepolia with account:", deployer.address);

  // Deploy FHEVM first
  const FHEVM = await ethers.getContractFactory("FHEVM");
  const fhevm = await FHEVM.deploy();
  await fhevm.waitForDeployment();
  const fhevmAddress = await fhevm.getAddress();
  console.log("FHEVM deployed to:", fhevmAddress);

  // Deploy Credit Oracle
  const CreditOracle = await ethers.getContractFactory("FHECreditOracle");
  const creditOracle = await CreditOracle.deploy(fhevmAddress);
  await creditOracle.waitForDeployment();
  const creditOracleAddress = await creditOracle.getAddress();
  console.log("CreditOracle deployed to:", creditOracleAddress);

  // Allow Credit Oracle to use FHEVM
  await fhevm.allowContract(creditOracleAddress);
  console.log("CreditOracle authorized on FHEVM");

  // Add some demo lending pools
  console.log("Adding demo lending pools...");
  
  // Pool 1: Conservative
  const minScore1 = await fhevm.encrypt(600);
  const maxLoan1 = await fhevm.encrypt(10000);
  await creditOracle.addLendingPool(
    deployer.address,
    minScore1,
    maxLoan1,
    800, // 8% interest
    "Conservative Pool"
  );

  // Pool 2: Balanced
  const minScore2 = await fhevm.encrypt(700);
  const maxLoan2 = await fhevm.encrypt(25000);
  await creditOracle.addLendingPool(
    deployer.address,
    minScore2,
    maxLoan2,
    600, // 6% interest
    "Balanced Pool"
  );

  // Pool 3: Aggressive
  const minScore3 = await fhevm.encrypt(800);
  const maxLoan3 = await fhevm.encrypt(50000);
  await creditOracle.addLendingPool(
    deployer.address,
    minScore3,
    maxLoan3,
    400, // 4% interest
    "Premium Pool"
  );

  console.log("Demo setup complete!");
  console.log("\n=== SEPOLIA DEPLOYMENT SUMMARY ===");
  console.log("FHEVM Address:", fhevmAddress);
  console.log("CreditOracle Address:", creditOracleAddress);
  console.log("Network: Sepolia Testnet");
  console.log("Deployer:", deployer.address);
  console.log("===================================");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
