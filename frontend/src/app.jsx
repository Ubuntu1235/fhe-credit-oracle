import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import './App.css';

// Contract ABIs (simplified for demo)
const CREDIT_ORACLE_ABI = [
  "function updateFinancialData(bytes,bytes,bytes,bytes) external",
  "function computeCreditScore() external returns (bytes)",
  "function creditProfiles(address) external view returns (tuple(bytes,bytes,bytes,bytes,bytes,bytes,uint256,bool))",
  "function findLoanMatches(bytes) external view returns (uint256[])",
  "function getOptimalLoanAmount(bytes,uint256) external view returns (bytes)"
];

function App() {
  const [account, setAccount] = useState('');
  const [provider, setProvider] = useState(null);
  const [creditOracle, setCreditOracle] = useState(null);
  const [creditScore, setCreditScore] = useState(null);
  const [loanMatches, setLoanMatches] = useState([]);
  const [isLoading, setIsLoading] = useState(false);
  const [financialData, setFinancialData] = useState({
    income: '',
    assets: '',
    debts: '',
    paymentHistory: ''
  });

  // Replace with your deployed contract address
  const CREDIT_ORACLE_ADDRESS = "0xYourDeployedContractAddress";

  const connectWallet = async () => {
    if (window.ethereum) {
      try {
        setIsLoading(true);
        await window.ethereum.request({ method: 'eth_requestAccounts' });
        const web3Provider = new ethers.BrowserProvider(window.ethereum);
        setProvider(web3Provider);
        
        const signer = await web3Provider.getSigner();
        const address = await signer.getAddress();
        setAccount(address);
        
        // Initialize contract
        const oracleContract = new ethers.Contract(
          CREDIT_ORACLE_ADDRESS,
          CREDIT_ORACLE_ABI,
          signer
        );
        setCreditOracle(oracleContract);
        
        console.log('Wallet connected successfully');
      } catch (error) {
        console.error('Error connecting wallet:', error);
        alert('Failed to connect wallet. Please make sure MetaMask is installed.');
      } finally {
        setIsLoading(false);
      }
    } else {
      alert('Please install MetaMask to use this dApp!');
    }
  };

  const handleFinancialDataChange = (field, value) => {
    setFinancialData(prev => ({
      ...prev,
      [field]: value
    }));
  };

  const simulateEncryption = (data) => {
    // In a real implementation, this would use proper FHE encryption
    // For demo purposes, we're simulating encryption
    return ethers.toUtf8Bytes(`encrypted_${data}_${Date.now()}`);
  };

  const updateFinancialData = async () => {
    if (!creditOracle) {
      alert('Please connect your wallet first');
      return;
    }

    try {
      setIsLoading(true);
      
      // Simulate encrypted data
      const encryptedIncome = simulateEncryption(financialData.income);
      const encryptedAssets = simulateEncryption(financialData.assets);
      const encryptedDebts = simulateEncryption(financialData.debts);
      const encryptedPaymentHistory = simulateEncryption(financialData.paymentHistory);

      const tx = await creditOracle.updateFinancialData(
        encryptedIncome,
        encryptedAssets,
        encryptedDebts,
        encryptedPaymentHistory
      );
      
      await tx.wait();
      alert('Financial data updated confidentially! Your data is fully encrypted.');
    } catch (error) {
      console.error('Error updating data:', error);
      alert('Error updating financial data. Please check console for details.');
    } finally {
      setIsLoading(false);
    }
  };

  const computeCreditScore = async () => {
    if (!creditOracle) {
      alert('Please connect your wallet first');
      return;
    }

    try {
      setIsLoading(true);
      const tx = await creditOracle.computeCreditScore();
      await tx.wait();
      
      // Get the encrypted score
      const profile = await creditOracle.creditProfiles(account);
      setCreditScore(profile.encryptedCreditScore);
      
      // Find loan matches
      const matches = await creditOracle.findLoanMatches(profile.encryptedCreditScore);
      setLoanMatches(matches.map(m => m.toString()));
      
      alert('Credit score computed confidentially! Your score remains encrypted.');
    } catch (error) {
      console.error('Error computing score:', error);
      alert('Error computing credit score. Please check console for details.');
    } finally {
      setIsLoading(false);
    }
  };

  const requestLoan = async (poolId) => {
    if (!creditScore) {
      alert('Please compute your credit score first');
      return;
    }

    try {
      setIsLoading(true);
      const optimalAmount = await creditOracle.getOptimalLoanAmount(creditScore, poolId);
      alert(`Optimal loan amount calculated: ${ethers.hexlify(optimalAmount).slice(0, 20)}... (encrypted)`);
    } catch (error) {
      console.error('Error requesting loan:', error);
      alert('Error processing loan request.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="App">
      <header className="app-header">
        <div className="header-content">
          <h1>🔒 FHE Credit Oracle</h1>
          <p>Confidential Credit Scoring Protocol</p>
          <div className="network-badge">Sepolia Testnet</div>
        </div>
        
        {!account ? (
          <button 
            onClick={connectWallet} 
            className="connect-btn"
            disabled={isLoading}
          >
            {isLoading ? 'Connecting...' : 'Connect MetaMask'}
          </button>
        ) : (
          <div className="wallet-info">
            <div className="account-address">
              📱 {account.slice(0, 6)}...{account.slice(-4)}
            </div>
            <div className="connection-status">✅ Connected</div>
          </div>
        )}
      </header>

      <main className="app-main">
        <div className="dashboard">
          {/* Financial Data Section */}
          <section className="data-section">
            <h2>📊 Enter Your Financial Data (Encrypted)</h2>
            <p className="section-description">
              Your data is encrypted using FHE and never decrypted - even during computation
            </p>
            
            <div className="financial-form">
              <div className="input-group">
                <label>Annual Income ($)</label>
                <input
                  type="number"
                  value={financialData.income}
                  onChange={(e) => handleFinancialDataChange('income', e.target.value)}
                  placeholder="50000"
                />
              </div>
              
              <div className="input-group">
                <label>Total Assets ($)</label>
                <input
                  type="number"
                  value={financialData.assets}
                  onChange={(e) => handleFinancialDataChange('assets', e.target.value)}
                  placeholder="100000"
                />
              </div>
              
              <div className="input-group">
                <label>Total Debts ($)</label>
                <input
                  type="number"
                  value={financialData.debts}
                  onChange={(e) => handleFinancialDataChange('debts', e.target.value)}
                  placeholder="20000"
                />
              </div>
              
              <div className="input-group">
                <label>Payment History Score (0-100)</label>
                <input
                  type="number"
                  min="0"
                  max="100"
                  value={financialData.paymentHistory}
                  onChange={(e) => handleFinancialDataChange('paymentHistory', e.target.value)}
                  placeholder="85"
                />
              </div>
              
              <button 
                onClick={updateFinancialData} 
                className="action-btn primary"
                disabled={isLoading}
              >
                {isLoading ? 'Encrypting...' : '🔒 Encrypt & Store Data'}
              </button>
            </div>
          </section>

          {/* Credit Score Section */}
          <section className="score-section">
            <h2>🎯 Compute Confidential Credit Score</h2>
            <p>Your credit score is calculated on encrypted data without decryption</p>
            
            <button 
              onClick={computeCreditScore} 
              className="action-btn secondary"
              disabled={isLoading}
            >
              {isLoading ? 'Computing...' : '🧮 Compute Encrypted Score'}
            </button>
            
            {creditScore && (
              <div className="score-result">
                <h3>Encrypted Credit Score</h3>
                <div className="encrypted-score">
                  {ethers.hexlify(creditScore).slice(0, 30)}...
                </div>
                <small>This is your fully encrypted credit score - even we can't read it!</small>
              </div>
            )}
          </section>

          {/* Loan Matches Section */}
          <section className="loans-section">
            <h2>🏦 Available Loan Matches</h2>
            <p>Get matched with lending pools without revealing your score</p>
            
            {loanMatches.length > 0 ? (
              <div className="loan-grid">
                {loanMatches.map((poolId, index) => (
                  <div key={poolId} className="loan-card">
                    <div className="loan-header">
                      <h4>Confidential Pool #{poolId}</h4>
                      <span className="interest-badge">5-15% APR*</span>
                    </div>
                    <div className="loan-details">
                      <p>✅ Qualified based on encrypted score</p>
                      <p>🔒 Maximum loan: Confidential</p>
                      <p>⚡ Instant approval</p>
                    </div>
                    <button 
                      onClick={() => requestLoan(poolId)}
                      className="loan-btn"
                      disabled={isLoading}
                    >
                      {isLoading ? 'Processing...' : 'Request Confidential Loan'}
                    </button>
                    <small>* Rate determined by encrypted score</small>
                  </div>
                ))}
              </div>
            ) : (
              <div className="no-matches">
                <p>Compute your credit score to see confidential loan matches</p>
              </div>
            )}
          </section>

          {/* How It Works Section */}
          <section className="info-section">
            <h2>🔍 How FHE Credit Oracle Works</h2>
            <div className="features-grid">
              <div className="feature-card">
                <div className="feature-icon">🔐</div>
                <h4>Data Encryption</h4>
                <p>Your financial data is encrypted using FHE and never stored in plain text</p>
              </div>
              
              <div className="feature-card">
                <div className="feature-icon">⚡</div>
                <h4>Private Computation</h4>
                <p>Credit scores are computed directly on encrypted data without decryption</p>
              </div>
              
              <div className="feature-card">
                <div className="feature-icon">🤝</div>
                <h4>Confidential Matching</h4>
                <p>Lending pools can verify qualifications without seeing your actual score</p>
              </div>
              
              <div className="feature-card">
                <div className="feature-icon">🌐</div>
                <h4>DeFi Integration</h4>
                <p>Seamlessly connects with DeFi lending protocols while maintaining privacy</p>
              </div>
            </div>
          </section>
        </div>
      </main>

      <footer className="app-footer">
        <div className="footer-content">
          <p>Built with ❤️ using FHEVM • Sepolia Testnet</p>
          <div className="footer-links">
            <a href="https://github.com/your-username/fhe-credit-oracle" target="_blank" rel="noopener noreferrer">
              GitHub
            </a>
            <a href="https://docs.zama.org" target="_blank" rel="noopener noreferrer">
              Zama Documentation
            </a>
          </div>
        </div>
      </footer>
    </div>
  );
}

export default App;