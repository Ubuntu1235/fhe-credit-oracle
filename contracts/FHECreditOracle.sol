// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFHEVM {
    function encrypt(uint256 value) external view returns (bytes memory);
    function add(bytes memory a, bytes memory b) external view returns (bytes memory);
    function multiply(bytes memory a, uint256 b) external view returns (bytes memory);
    function decrypt(bytes memory ciphertext) external view returns (uint256);
    function compare(bytes memory a, bytes memory b) external view returns (bool);
}

contract FHECreditOracle {
    IFHEVM public fhevm;
    
    struct CreditProfile {
        bytes encryptedIncome;
        bytes encryptedAssets;
        bytes encryptedDebts;
        bytes encryptedPaymentHistory; // 0-100 score
        bytes encryptedCreditUtilization; // 0-100%
        bytes encryptedCreditScore; // Final computed score
        uint256 lastUpdated;
        bool exists;
    }
    
    struct LendingPool {
        address poolAddress;
        bytes encryptedMinScore;
        bytes encryptedMaxLoanAmount;
        uint256 interestRate; // in basis points
        bool isActive;
    }
    
    mapping(address => CreditProfile) public creditProfiles;
    mapping(address => bool) public authorizedDataProviders;
    LendingPool[] public lendingPools;
    
    event CreditProfileUpdated(address user);
    event CreditScoreComputed(address user, bytes encryptedScore);
    event LendingPoolAdded(uint256 poolId, address poolAddress);
    event LoanMatchFound(address user, uint256 poolId, bytes encryptedAmount);
    
    constructor(address _fhevmAddress) {
        fhevm = IFHEVM(_fhevmAddress);
        authorizedDataProviders[msg.sender] = true;
    }
    
    function addDataProvider(address provider) external {
        require(msg.sender == address(this) || authorizedDataProviders[msg.sender], "Unauthorized");
        authorizedDataProviders[provider] = true;
    }
    
    function updateFinancialData(
        bytes memory _encryptedIncome,
        bytes memory _encryptedAssets,
        bytes memory _encryptedDebts,
        bytes memory _encryptedPaymentHistory
    ) external {
        CreditProfile storage profile = creditProfiles[msg.sender];
        
        profile.encryptedIncome = _encryptedIncome;
        profile.encryptedAssets = _encryptedAssets;
        profile.encryptedDebts = _encryptedDebts;
        profile.encryptedPaymentHistory = _encryptedPaymentHistory;
        profile.lastUpdated = block.timestamp;
        profile.exists = true;
        
        emit CreditProfileUpdated(msg.sender);
    }
    
    function computeCreditScore() external returns (bytes memory) {
        require(creditProfiles[msg.sender].exists, "No credit profile");
        CreditProfile storage profile = creditProfiles[msg.sender];
        
        // FHE-based credit scoring algorithm:
        // Score = (PaymentHistory * 0.35) + (Income/Assets * 0.30) + (DebtUtilization * 0.20) + (AssetDiversity * 0.15)
        
        // Calculate debt-to-income ratio (encrypted)
        bytes memory debtToIncome = fhevm.multiply(profile.encryptedDebts, 100); // Convert to percentage
        debtToIncome = fhevm.add(debtToIncome, profile.encryptedIncome); // Avoid division in FHE
        
        // Calculate credit utilization (encrypted)
        bytes memory creditUtilization = profile.encryptedCreditUtilization;
        
        // Weighted scoring (all operations in FHE)
        bytes memory paymentScore = fhevm.multiply(profile.encryptedPaymentHistory, 35);
        bytes memory incomeScore = fhevm.multiply(profile.encryptedIncome, 3); // Simplified for demo
        bytes memory utilizationScore = fhevm.multiply(creditUtilization, 20);
        bytes memory assetScore = fhevm.multiply(profile.encryptedAssets, 15);
        
        // Combine scores
        bytes memory totalScore = fhevm.add(paymentScore, incomeScore);
        totalScore = fhevm.add(totalScore, utilizationScore);
        totalScore = fhevm.add(totalScore, assetScore);
        
        profile.encryptedCreditScore = totalScore;
        
        emit CreditScoreComputed(msg.sender, totalScore);
        return totalScore;
    }
    
    function addLendingPool(
        address _poolAddress,
        bytes memory _encryptedMinScore,
        bytes memory _encryptedMaxLoanAmount,
        uint256 _interestRate
    ) external {
        require(authorizedDataProviders[msg.sender], "Unauthorized");
        
        lendingPools.push(LendingPool({
            poolAddress: _poolAddress,
            encryptedMinScore: _encryptedMinScore,
            encryptedMaxLoanAmount: _encryptedMaxLoanAmount,
            interestRate: _interestRate,
            isActive: true
        }));
        
        emit LendingPoolAdded(lendingPools.length - 1, _poolAddress);
    }
    
    function findLoanMatches(bytes memory _encryptedUserScore) external view returns (uint256[] memory) {
        uint256[] memory matches = new uint256[](lendingPools.length);
        uint256 matchCount = 0;
        
        for (uint256 i = 0; i < lendingPools.length; i++) {
            if (lendingPools[i].isActive) {
                // Compare encrypted scores without decryption
                bool isQualified = fhevm.compare(
                    _encryptedUserScore, 
                    lendingPools[i].encryptedMinScore
                );
                
                if (isQualified) {
                    matches[matchCount] = i;
                    matchCount++;
                }
            }
        }
        
        // Resize array
        uint256[] memory result = new uint256[](matchCount);
        for (uint256 i = 0; i < matchCount; i++) {
            result[i] = matches[i];
        }
        
        return result;
    }
    
    function getOptimalLoanAmount(
        bytes memory _encryptedUserScore,
        uint256 poolId
    ) external view returns (bytes memory) {
        require(poolId < lendingPools.length, "Invalid pool");
        LendingPool memory pool = lendingPools[poolId];
        
        // Calculate loan amount based on score without decryption
        bytes memory loanAmount = fhevm.multiply(_encryptedUserScore, 100); // Scale factor
        
        // Ensure it doesn't exceed pool maximum
        bool exceedsMax = fhevm.compare(loanAmount, pool.encryptedMaxLoanAmount);
        if (exceedsMax) {
            return pool.encryptedMaxLoanAmount;
        }
        
        return loanAmount;
    }
}