// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title FHEVM - Fully Homomorphic Encryption Virtual Machine
 * @dev Simulates FHE operations for the credit oracle demo
 * In production, this would integrate with Zama's fhEVM
 */
contract FHEVM {
    address public owner;
    
    // Mapping to track allowed contracts that can use FHE operations
    mapping(address => bool) public allowedContracts;
    
    // Event for FHE operations
    event FHEOperation(string operation, address user, bytes encryptedData);
    event ContractAllowed(address contractAddress);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "FHEVM: Only owner can call this function");
        _;
    }
    
    modifier onlyAllowed() {
        require(allowedContracts[msg.sender], "FHEVM: Contract not allowed to use FHE operations");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        allowedContracts[msg.sender] = true;
    }
    
    /**
     * @dev Allow a contract to use FHE operations
     */
    function allowContract(address contractAddress) external onlyOwner {
        allowedContracts[contractAddress] = true;
        emit ContractAllowed(contractAddress);
    }
    
    /**
     * @dev Disallow a contract from using FHE operations
     */
    function disallowContract(address contractAddress) external onlyOwner {
        allowedContracts[contractAddress] = false;
    }
    
    /**
     * @dev Encrypt a uint256 value (simulated FHE encryption)
     * In production, this would use actual FHE encryption from Zama
     */
    function encrypt(uint256 value) external view onlyAllowed returns (bytes memory) {
        // Simulate FHE encryption - in production this would be real FHE
        bytes memory encrypted = abi.encodePacked(
            bytes32(uint256(keccak256(abi.encodePacked(value, block.timestamp, msg.sender)))),
            bytes32(value)
        );
        
        emit FHEOperation("encrypt", msg.sender, encrypted);
        return encrypted;
    }
    
    /**
     * @dev Add two encrypted values (homomorphic addition)
     */
    function add(bytes memory a, bytes memory b) external view onlyAllowed returns (bytes memory) {
        require(a.length == 64 && b.length == 64, "FHEVM: Invalid encrypted data length");
        
        // Extract values from "encrypted" data (simulation)
        uint256 valueA = extractValue(a);
        uint256 valueB = extractValue(b);
        uint256 result = valueA + valueB;
        
        // Return "encrypted" result
        bytes memory encryptedResult = abi.encodePacked(
            bytes32(uint256(keccak256(abi.encodePacked(result, block.timestamp, msg.sender)))),
            bytes32(result)
        );
        
        emit FHEOperation("add", msg.sender, encryptedResult);
        return encryptedResult;
    }
    
    /**
     * @dev Multiply an encrypted value by a scalar (homomorphic multiplication)
     */
    function multiply(bytes memory a, uint256 scalar) external view onlyAllowed returns (bytes memory) {
        require(a.length == 64, "FHEVM: Invalid encrypted data length");
        
        uint256 valueA = extractValue(a);
        uint256 result = valueA * scalar;
        
        bytes memory encryptedResult = abi.encodePacked(
            bytes32(uint256(keccak256(abi.encodePacked(result, block.timestamp, msg.sender)))),
            bytes32(result)
        );
        
        emit FHEOperation("multiply", msg.sender, encryptedResult);
        return encryptedResult;
    }
    
    /**
     * @dev Compare two encrypted values (homomorphic comparison)
     * Returns true if a >= b
     */
    function compare(bytes memory a, bytes memory b) external view onlyAllowed returns (bool) {
        require(a.length == 64 && b.length == 64, "FHEVM: Invalid encrypted data length");
        
        uint256 valueA = extractValue(a);
        uint256 valueB = extractValue(b);
        
        emit FHEOperation("compare", msg.sender, a);
        return valueA >= valueB;
    }
    
    /**
     * @dev Decrypt an encrypted value (for demo purposes - in real FHE this would be limited)
     */
    function decrypt(bytes memory ciphertext) external view onlyAllowed returns (uint256) {
        require(ciphertext.length == 64, "FHEVM: Invalid ciphertext length");
        
        uint256 value = extractValue(ciphertext);
        
        emit FHEOperation("decrypt", msg.sender, ciphertext);
        return value;
    }
    
    /**
     * @dev Extract value from simulated encrypted data
     */
    function extractValue(bytes memory data) internal pure returns (uint256) {
        bytes32 valuePart;
        assembly {
            valuePart := mload(add(data, 32))
        }
        return uint256(valuePart);
    }
    
    /**
     * @dev Get FHEVM version and capabilities
     */
    function getVersion() external pure returns (string memory) {
        return "FHEVM v1.0.0 - Credit Oracle Demo";
    }
    
    /**
     * @dev Check if a contract is allowed to use FHE operations
     */
    function isAllowed(address contractAddress) external view returns (bool) {
        return allowedContracts[contractAddress];
    }
}
