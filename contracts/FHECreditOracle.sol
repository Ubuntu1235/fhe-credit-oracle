// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./FHEVM.sol";

/**
 * @title FHECreditOracle - Confidential Credit Scoring using FHE
 * @dev Uses FHEVM for encrypted credit score computations
 */
contract FHECreditOracle {
    FHEVM public fhevm;
    address public owner;
    
    struct CreditProfile {
        bytes encryptedIncome;
        bytes encryptedAssets;
        bytes encryptedDebts;
        bytes encryptedPaymentHistory;
        bytes encryptedCreditUtilization;
        bytes encryptedCreditScore;
        uint256 lastUpdated;
        bool exists;
    }
    
    struct LendingPool {
        address poolAddress;
        bytes encryptedMinScore;
        bytes encryptedMaxLoanAmount;
        uint256 interestRate; // in basis points
        bool isActive;
        string name;
    }
    
    mapping(address => CreditProfile) public creditProfiles;
    mapping(address => bool) public authorizedDataProviders;
    LendingPool[] public lendingPools;
    
    uint256 public constant SCORE_SCALE = 1000;
    
    event CreditProfileUpdated(address indexed user);
    event CreditScoreComputed(address indexed user, bytes encryptedScore);
    event LendingPoolAdded(uint256 indexed poolId, address poolAddress, string name);
    event LoanMatchFound(address indexed user, uint256 poolId, bytes encryptedAmount);
    event DataProviderAuthorized(address provider);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyAuthorized() {
        require(authorizedDataProviders[msg.sender] || msg.sender == owner, "Not authorized");
        _;
    }
    
    constructor(address _fhevmAddress) {
        fhevm = FHEVM(_fhevmAddress);
        owner = msg.sender;
        authorizedDataProviders[msg.sender] = true;
    }
    
    /**
     * @dev Authorize a data provider to update credit information
     */
    function authorizeDataProvider(address provider) external onlyOwner {
        authorizedDataProviders[provider] = true;
        emit DataProviderAuthorized(provider);
    }
    
    /**
     * @dev Update user's financial data with FHE encryption
     */
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
    
    /**
     * @dev Compute credit score using FHE operations
     * Score = (PaymentHistory * 0.35) + (Income/Assets factor * 0.30) + (DebtUtilization * 0.20) + (AssetDiversity * 0.15)
     */
    function computeCreditScore() external returns (bytes memory) {
        require(creditProfiles[msg.sender].exists, "No credit profile found");
        
        CreditProfile storage profile = creditProfiles[msg.sender];
        
        // All operations are done on encrypted data using FHE
        
        // 1. Payment History (35% weight)
        bytes memory paymentScore = fhevm.multiply(profile.encryptedPaymentHistory, 35);
        
        // 2. Income/Assets factor (30% weight) - simplified for demo
        bytes memory incomeAssetsScore = fhevm.multiply(profile.encryptedIncome, 3);
        
        // 3. Debt utilization (20% weight)
        bytes memory utilizationScore = fhevm.multiply(profile.encryptedDebts, 2);
        
        // 4. Asset diversity (15% weight)
        bytes memory assetScore = fhevm.multiply(profile.encryptedAssets, 15);
        
        // Combine all scores (homomorphic addition)
        bytes memory totalScore = fhevm.add(paymentScore, incomeAssetsScore);
        totalScore = fhevm.add(totalScore, utilizationScore);
        totalScore = fhevm.add(totalScore, assetScore);
        
        // Scale the score
        totalScore = fhevm.multiply(totalScore, SCORE_SCALE / 100);
        
        profile.encryptedCreditScore = totalScore;
        
        emit CreditScoreComputed(msg.sender, totalScore);
        return totalScore;
    }
    
    /**
     * @dev Add a lending pool with encrypted minimum score requirements
     */
    function addLendingPool(
        address _poolAddress,
        bytes memory _encryptedMinScore,
        bytes memory _encryptedMaxLoanAmount,
        uint256 _interestRate,
        string memory _name
    ) external onlyAuthorized {
        lendingPools.push(LendingPool({
            poolAddress: _poolAddress,
            encryptedMinScore: _encryptedMinScore,
            encryptedMaxLoanAmount: _encryptedMaxLoanAmount,
            interestRate: _interestRate,
            isActive: true,
            name: _name
        }));
        
        emit LendingPoolAdded(lendingPools.length - 1, _poolAddress, _name);
    }
    
    /**
     * @dev Find loan matches without decrypting user's score
     */
    function findLoanMatches(bytes memory _encryptedUserScore) external view returns (uint256[] memory) {
        uint256 matchCount = 0;
        uint256[] memory tempMatches = new uint256[](lendingPools.length);
        
        for (uint256 i = 0; i < lendingPools.length; i++) {
            if (lendingPools[i].isActive) {
                // Compare encrypted scores without decryption
                bool isQualified = fhevm.compare(
                    _encryptedUserScore, 
                    lendingPools[i].encryptedMinScore
                );
                
                if (isQualified) {
                    tempMatches[matchCount] = i;
                    matchCount++;
                }
            }
        }
        
        // Create properly sized array
        uint256[] memory matches = new uint256[](matchCount);
        for (uint256 i = 0; i < matchCount; i++) {
            matches[i] = tempMatches[i];
        }
        
        return matches;
    }
    
    /**
     * @dev Get optimal loan amount based on encrypted credit score
     */
    function getOptimalLoanAmount(
        bytes memory _encryptedUserScore,
        uint256 poolId
    ) external view returns (bytes memory) {
        require(poolId < lendingPools.length, "Invalid pool ID");
        require(lendingPools[poolId].isActive, "Pool not active");
        
        LendingPool memory pool = lendingPools[poolId];
        
        // Calculate loan amount based on score (homomorphic multiplication)
        bytes memory loanAmount = fhevm.multiply(_encryptedUserScore, 10); // Scale factor
        
        // Ensure it doesn't exceed pool maximum (homomorphic comparison)
        bool exceedsMax = fhevm.compare(loanAmount, pool.encryptedMaxLoanAmount);
        if (exceedsMax) {
            return pool.encryptedMaxLoanAmount;
        }
        
        return loanAmount;
    }
    
    /**
     * @dev Get user's encrypted credit score
     */
    function getEncryptedCreditScore(address user) external view returns (bytes memory) {
        require(creditProfiles[user].exists, "No profile found");
        return creditProfiles[user].encryptedCreditScore;
    }
    
    /**
     * @dev Get lending pool count
     */
    function getLendingPoolCount() external view returns (uint256) {
        return lendingPools.length;
    }
    
    /**
     * @dev Get lending pool details
     */
    function getLendingPool(uint256 poolId) external view returns (
        address poolAddress,
        string memory name,
        uint256 interestRate,
        bool isActive
    ) {
        require(poolId < lendingPools.length, "Invalid pool ID");
        LendingPool memory pool = lendingPools[poolId];
        return (pool.poolAddress, pool.name, pool.interestRate, pool.isActive);
    }
}
