// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FHECreditOracle.sol";

contract ConfidentialLendingPool {
    FHECreditOracle public creditOracle;
    address public owner;
    
    struct Loan {
        address borrower;
        bytes encryptedAmount;
        bytes encryptedInterestRate;
        uint256 startTime;
        bool isActive;
        bool isRepaid;
    }
    
    mapping(address => Loan[]) public userLoans;
    uint256 public totalLiquidity;
    uint256 public utilizedLiquidity;
    
    event LoanIssued(address borrower, bytes encryptedAmount, uint256 loanId);
    event LoanRepaid(address borrower, uint256 loanId);
    
    constructor(address _creditOracle) {
        creditOracle = FHECreditOracle(_creditOracle);
        owner = msg.sender;
    }
    
    function addLiquidity() external payable {
        totalLiquidity += msg.value;
    }
    
    function requestLoan(bytes memory _encryptedCreditScore) external {
        // Get optimal loan amount without decrypting credit score
        bytes memory encryptedLoanAmount = creditOracle.getOptimalLoanAmount(
            _encryptedCreditScore,
            getPoolId()
        );
        
        // Calculate encrypted interest rate based on credit score
        bytes memory encryptedInterest = calculateInterestRate(_encryptedCreditScore);
        
        Loan memory newLoan = Loan({
            borrower: msg.sender,
            encryptedAmount: encryptedLoanAmount,
            encryptedInterestRate: encryptedInterest,
            startTime: block.timestamp,
            isActive: true,
            isRepaid: false
        });
        
        userLoans[msg.sender].push(newLoan);
        
        // Transfer funds (in real implementation, this would use encrypted amounts)
        uint256 loanAmount = decryptLoanAmount(encryptedLoanAmount);
        require(utilizedLiquidity + loanAmount <= totalLiquidity, "Insufficient liquidity");
        utilizedLiquidity += loanAmount;
        
        payable(msg.sender).transfer(loanAmount);
        
        emit LoanIssued(msg.sender, encryptedLoanAmount, userLoans[msg.sender].length - 1);
    }
    
    function calculateInterestRate(bytes memory _encryptedScore) internal view returns (bytes memory) {
        // Better scores get lower interest rates (all in FHE)
        // Base rate 10% - (score / 1000)%
        return fhevm.multiply(_encryptedScore, 10); // Simplified calculation
    }
    
    function decryptLoanAmount(bytes memory _encryptedAmount) internal view returns (uint256) {
        // In production, this would use proper FHE decryption
        // For demo, we'll use a simplified approach
        return abi.decode(_encryptedAmount, (uint256)) / 100; // Scale down
    }
    
    function getPoolId() internal view returns (uint256) {
        // Implementation to get this pool's ID from oracle
        return 0; // Simplified for demo
    }
}