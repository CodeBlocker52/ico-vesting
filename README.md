# SmartTokens ICO Contract

A comprehensive, production-ready ICO (Initial Coin Offering) token sale contract built with Foundry and OpenZeppelin v5. Features includes : multi-phase sales, whitelisting, vesting schedules, and advanced security mechanisms.

## 🚀 Key Features

### Core Functionality
- **ERC20 Token** with ERC20Permit (gasless approvals)
- **Multi-Phase ICO** with different pricing and caps
- **Whitelist/Blacklist** management system
- **Vesting Schedules** for team and advisors
- **Individual Purchase Caps** per phase
- **Real-time Purchase Tracking**

### Security Features
- **Reentrancy Protection** on all critical functions
- **Pausable Contract** for emergency situations  
- **Access Control** with role-based permissions
- **Custom Errors** for gas optimization
- **Input Validation** on all parameters
- **Emergency Withdrawal** capabilities

### Admin Controls
- **Phase Management** - Create/update ICO phases
- **Whitelist Management** - Add/remove users from whitelist
- **Treasury Management** - Configurable treasury address
- **ICO Finalization** - Burn remaining tokens
- **Fund Withdrawal** - Withdraw raised ETH to treasury
- **Vesting Creation** - Set up token vesting schedules

## 📊 Token Economics

- **Total Supply**: 1,000,000,000 SMART tokens
- **ICO Allocation**: 400,000,000 tokens (40%)
- **Team Allocation**: 200,000,000 tokens (20%)
- **Reserve**: 400,000,000 tokens (40%)

## 🏗️ Project Structure

```
smart-tokens-ico/
├── foundry.toml              # Foundry configuration
├── .env.example              # Environment variables template
├── src/
│   └── SmartTokens.sol       # Main contract
├── test/
│   ├── SmartTokens.t.sol     # Unit tests
│   ├── SmartTokensIntegration.t.sol # Integration tests
│   └── helpers/
│       └── TestHelper.sol    # Test utilities
├── script/
│   ├── Deploy.s.sol          # Deployment script
│   └── interactions/
│       ├── CreatePhases.s.sol    # Phase management
│       ├── ManageWhitelist.s.sol # Whitelist management
│       └── FinalizeICO.s.sol     # ICO finalization
└── README.md
```

## 🛠️ Setup & Installation

### Prerequisites
- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Git](https://git-scm.com/downloads)
- Node.js (optional, for additional tooling)

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd smart-tokens-ico
   ```

2. **Install dependencies**
   ```bash
   forge install
   ```

3. **Set up environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your actual values
   ```

4. **Build the project**
   ```bash
   forge build
   ```

## 🧪 Testing

### Run all tests
```bash
forge test
```

### Run tests with verbosity
```bash
forge test -vvv
```

### Run specific test file
```bash
forge test --match-contract SmartTokensTest
```

### Run specific test function
```bash
forge test --match-test testBuyTokens -vvv
```

### Generate test coverage
```bash
forge coverage
```

### Run gas report
```bash
forge test --gas-report
```

## 🚀 Deployment

### Deploy to Sepolia Testnet

1. **Set environment variables in `.env`**
   ```bash
   SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_INFURA_KEY
   PRIVATE_KEY=your_private_key_here
   ETHERSCAN_API_KEY=your_etherscan_api_key
   TREASURY_ADDRESS=0x1234567890123456789012345678901234567890
   ICO_START_TIME=1704067200  # Unix timestamp
   ICO_END_TIME=1735689600    # Unix timestamp
   ```forge script script/Deploy.s.sol --rpc-url sepolia --broadcast --verify -vvvv

2. **Deploy the contract**
   ```bash
   forge script script/Deploy.s.sol --rpc-url sepolia --broadcast --verify -vvvv
   ```

3. **Set the contract address in environment**
   ```bash
   export SMART_TOKENS_ADDRESS=0xYourDeployedContractAddress
   ```

### Deploy to Mainnet
```bash
forge script script/Deploy.s.sol --rpc-url mainnet --broadcast --verify -vvvv
```

## ⚙️ Contract Interaction Scripts

### Create ICO Phases
```bash
# Create additional phases with different pricing
forge script script/interactions/CreatePhases.s.sol --rpc-url sepolia --broadcast -vvvv
```

### Manage Whitelist
```bash
# Add users to whitelist
forge script script/interactions/ManageWhitelist.s.sol --sig "addToWhitelist()" --rpc-url sepolia --broadcast -vvvv

# Remove users from whitelist  
forge script script/interactions/ManageWhitelist.s.sol --sig "removeFromWhitelist()" --rpc-url sepolia --broadcast -vvvv

# Add bulk whitelist
forge script script/interactions/ManageWhitelist.s.sol --sig "addBulkWhitelist()" --rpc-url sepolia --broadcast -vvvv
```

### Finalize ICO
```bash
# Finalize ICO (burns remaining tokens)
forge script script/interactions/FinalizeICO.s.sol --sig "finalizeICO()" --rpc-url sepolia --broadcast -vvvv

# Withdraw funds to treasury
forge script script/interactions/FinalizeICO.s.sol --sig "withdrawFunds()" --rpc-url sepolia --broadcast -vvvv

# Create team vesting schedules
forge script script/interactions/FinalizeICO.s.sol --sig "createVestingSchedules()" --rpc-url sepolia --broadcast -vvvv
```

### Emergency Functions
```bash
# Pause contract
forge script script/interactions/FinalizeICO.s.sol --sig "emergencyPause()" --rpc-url sepolia --broadcast -vvvv

# Unpause contract
forge script script/interactions/FinalizeICO.s.sol --sig "emergencyUnpause()" --rpc-url sepolia --broadcast -vvvv

# Get ICO summary
forge script script/interactions/FinalizeICO.s.sol --sig "getICOSummary()" --rpc-url sepolia -vvvv
```

## 📖 User Flow

### For Regular Users

1. **Check Current Phase**
   - Visit the contract to see current phase details
   - Check pricing and individual caps

2. **Purchase Tokens**
   - Send ETH directly to contract address, or
   - Call `buyTokens()` function with ETH value
   - Tokens are instantly transferred to your wallet

3. **Track Purchases**
   - View your purchase history via `getUserPurchases()`
   - Check total purchased amount

### For Whitelisted Users

1. **Early Access**
   - Get added to whitelist by admin
   - Access exclusive early-bird phases
   - Higher individual purchase limits

2. **Purchase Process**
   - Same as regular users once whitelisted
   - Can participate in whitelist-only phases

### For Team Members

1. **Vesting Schedule**
   - Admin creates vesting schedule for you
   - Tokens vest linearly over time with cliff period

2. **Claim Vested Tokens**
   - Call `releaseVestedTokens()` to claim available tokens
   - Check `getReleasableAmount()` to see claimable amount

## 🔧 Admin Operations

### Phase Management
```solidity
// Create new phase
createPhase(phaseId, startTime, endTime, price, tokensAvailable, individualCap, requiresWhitelist)

// Update existing phase
updatePhase(phaseId, newPrice, newTokensAvailable, newIndividualCap, isActive)

// Set current active phase
setCurrentPhase(phaseId)
```

### User Management
```solidity
// Update whitelist
updateWhitelist(addresses[], true/false)

// Update blacklist  
updateBlacklist(addresses[], true/false)
```

### Treasury & Funds
```solidity
// Set treasury address
setTreasury(newTreasuryAddress)

// Withdraw specific amount
withdrawFunds(amount)

// Emergency withdraw all
emergencyWithdraw()
```

### Vesting Management
```solidity
// Create vesting schedule
createVestingSchedule(beneficiary, amount, startTime, duration, cliffDuration)
```

## 🔍 Contract Verification

After deployment, verify the contract on Etherscan:

```bash
forge verify-contract \
  --chain sepolia \
  --num-of-optimizations 200 \
  --watch \
  --constructor-args $(cast abi-encode "constructor(address,uint256,uint256)" $TREASURY_ADDRESS $ICO_START_TIME $ICO_END_TIME) \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --compiler-version v0.8.20 \
  $SMART_TOKENS_ADDRESS \
  src/SmartTokens.sol:SmartTokens
```

## 📈 Monitoring & Analytics

### View Functions for Monitoring
```solidity
// Get current phase information
getCurrentPhaseInfo()

// Get total raised funds
totalRaised()

// Get remaining tokens in phase
getRemainingTokensInPhase(phaseId)

// Check user's total purchases
userTotalPurchased(userAddress)

// Get user's purchase history
getUserPurchases(userAddress)

// Check whitelist/blacklist status
isWhitelisted(userAddress)
isBlacklisted(userAddress)
```

### Events for Off-chain Tracking
- `TokensPurchased(buyer, amount, price, phase)`
- `PhaseCreated(phaseId, startTime, endTime, price)`
- `WhitelistUpdated(user, status)`
- `VestingScheduleCreated(beneficiary, amount, startTime, duration)`
- `ICOFinalized(totalRaised, tokensSold)`

## 🛡️ Security Considerations

### Smart Contract Security
- **Reentrancy Protection**: `nonReentrant` modifier on critical functions
- **Access Control**: `onlyOwner` modifier for admin functions
- **Input Validation**: Custom errors for invalid parameters
- **Pausable**: Emergency stop functionality
- **Blacklist**: Block malicious addresses
- **Time-based Controls**: ICO start/end time enforcement
- **Supply Management**: Burn remaining tokens after ICO

### Operational Security
- **Multi-signature Wallet**: Use multisig for owner/treasury addresses
- **Timelock**: Consider timelock for critical admin functions
- **Monitoring**: Set up event monitoring for suspicious activities
- **Gradual Launch**: Start with small phases to test functionality

## 🎯 Usage Examples

### Buying Tokens (User)
```javascript
// Using ethers.js
const smartTokens = new ethers.Contract(contractAddress, abi, signer);

// Buy tokens by sending ETH
await smartTokens.buyTokens({ value: ethers.utils.parseEther("1.0") });

// Or send ETH directly to contract
await signer.sendTransaction({
  to: contractAddress,
  value: ethers.utils.parseEther("1.0")
});
```

### Admin Operations
```javascript
// Add users to whitelist
const addresses = ["0x123...", "0x456...", "0x789..."];
await smartTokens.updateWhitelist(addresses, true);

// Create new phase
await smartTokens.createPhase(
  2, // phaseId
  startTime,
  endTime, 
  ethers.utils.parseEther("0.001"), // price per token
  ethers.utils.parseEther("100000000"), // tokens available
  ethers.utils.parseEther("1000000"), // individual cap
  false // requires whitelist
);

// Set current phase
await smartTokens.setCurrentPhase(2);
```

## 🧪 Testing Strategy

### Unit Tests Coverage
- ✅ Deployment and initialization
- ✅ Phase creation and management  
- ✅ Whitelist/blacklist functionality
- ✅ Token purchase logic
- ✅ Individual and phase caps
- ✅ Vesting schedule creation and release
- ✅ Admin controls (pause, finalize, withdraw)
- ✅ Access control and permissions
- ✅ Edge cases and error conditions

### Integration Tests Coverage
- ✅ Full ICO lifecycle simulation
- ✅ Multi-phase token purchases
- ✅ Complex vesting scenarios
- ✅ Large-scale user interactions
- ✅ Emergency scenarios
- ✅ Gas optimization verification

### Test Commands Summary
```bash
# Run all tests
forge test

# Run with gas report
forge test --gas-report

# Run specific test categories
forge test --match-contract SmartTokensTest      # Unit tests
forge test --match-contract SmartTokensIntegrationTest # Integration tests

# Run tests with different verbosity levels
forge test -v    # Minimal output
forge test -vv   # Show test results
forge test -vvv  # Show stack traces for failing tests
forge test -vvvv # Show stack traces for all tests + setup

# Run coverage analysis
forge coverage
forge coverage --report lcov # Generate LCOV report
```

## 🔄 Development Workflow

### Local Development
1. **Make changes** to contracts in `src/`
2. **Write tests** in `test/`
3. **Run tests** with `forge test`
4. **Check coverage** with `forge coverage`
5. **Build contracts** with `forge build`

### Deployment Workflow
1. **Test on local fork**
   ```bash
   anvil --fork-url $SEPOLIA_RPC_URL
   forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast
   ```

2. **Deploy to testnet**
   ```bash
   forge script script/Deploy.s.sol --rpc-url sepolia --broadcast --verify
   ```

3. **Verify and test on testnet**
   - Interact with deployed contract
   - Test all functionality
   - Monitor events and gas usage

4. **Deploy to mainnet** (after thorough testing)
   ```bash
   forge script script/Deploy.s.sol --rpc-url mainnet --broadcast --verify
   ```

## 📋 Checklist for Deployment

### Pre-deployment
- [ ] All tests passing
- [ ] Code reviewed and audited
- [ ] Treasury address configured
- [ ] ICO timing set correctly
- [ ] Gas optimization verified
- [ ] Event monitoring set up

### Post-deployment
- [ ] Contract verified on Etherscan
- [ ] Initial phases created
- [ ] Whitelist populated
- [ ] Treasury confirmed
- [ ] Emergency procedures tested
- [ ] Monitoring dashboards active

## 🚨 Emergency Procedures

### If Issues Detected
1. **Immediate Response**
   ```bash
   # Pause the contract
   forge script script/interactions/FinalizeICO.s.sol --sig "emergencyPause()" --rpc-url sepolia --broadcast
   ```

2. **Investigation**
   - Check transaction logs
   - Analyze contract state
   - Identify root cause

3. **Resolution**
   - Fix issues if possible
   - Communicate with users
   - Unpause when safe

### Fund Recovery
```bash
# Emergency withdraw all funds to treasury
forge script script/interactions/FinalizeICO.s.sol --sig "withdrawFunds()" --rpc-url sepolia --broadcast
```

## 📊 Gas Optimization

### Optimizations Implemented
- **Custom Errors**: Instead of require strings (saves ~50 gas per revert)
- **Packed Structs**: Efficient storage layout
- **Batch Operations**: Whitelist updates in batches
- **Event Optimization**: Indexed parameters for filtering
- **Storage vs Memory**: Proper usage based on context

### Gas Usage Estimates
- Deploy: ~3,500,000 gas
- Buy tokens: ~80,000 gas
- Whitelist update (batch of 50): ~350,000 gas
- Create phase: ~120,000 gas
- Finalize ICO: ~45,000 gas

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Write tests for your changes
4. Ensure all tests pass (`forge test`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚠️ Disclaimer

This software is provided "as is" without warranty. Use at your own risk. Always conduct thorough testing and security audits before deploying to mainnet with real funds.

## 📞 Support

- **Issues**: Open a GitHub issue
- **Discussions**: Use GitHub Discussions
- **Security**: Email security@example.com for security-related issues

## 🔗 Useful Links

- [Foundry Documentation](https://book.getfoundry.sh/)
- [OpenZeppelin Documentation](https://docs.openzeppelin.com/)
- [Solidity Documentation](https://docs.soliditylang.org/)
- [Ethereum Gas Tracker](https://etherscan.io/gastracker)

---

## 📈 Advanced Usage

### Custom Phase Pricing Strategy

Create phases with different pricing models:

```solidity
// Phase 1: Early bird (50% discount)
createPhase(1, start, start + 7 days, 0.0005 ether, 50_000_000 * 10**18, 2_000_000 * 10**18, true);

// Phase 2: Private sale (30% discount) 
createPhase(2, start + 7 days, start + 21 days, 0.0007 ether, 100_000_000 * 10**18, 1_000_000 * 10**18, true);

// Phase 3: Pre-sale (20% discount)
createPhase(3, start + 21 days, start + 45 days, 0.0008 ether, 150_000_000 * 10**18, 500_000 * 10**18, false);

// Phase 4: Public sale (base price)
createPhase(4, start + 45 days, end, 0.001 ether, 100_000_000 * 10**18, 100_000 * 10**18, false);
```

### Vesting Schedule Examples

```solidity
// Team vesting: 4-year linear vesting with 1-year cliff
createVestingSchedule(teamMember, 10_000_000 * 10**18, block.timestamp, 4 * 365 days, 365 days);

// Advisor vesting: 2-year linear vesting with 6-month cliff  
createVestingSchedule(advisor, 1_000_000 * 10**18, block.timestamp, 2 * 365 days, 180 days);

// Partner vesting: 3-year linear vesting, no cliff
createVestingSchedule(partner, 5_000_000 * 10**18, block.timestamp, 3 * 365 days, 0);
```

This comprehensive documentation provides everything needed to understand, deploy, test, and operate the SmartTokens ICO contract successfully.