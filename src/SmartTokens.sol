// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/utils/Pausable.sol";
import "openzeppelin-contracts/contracts/utils/math/Math.sol";

/**
 * @title SmartTokens ICO Contract
 * @dev A comprehensive ICO token sale contract with multi-phase sales,
 * whitelisting, vesting, and security features
 */
contract SmartTokens is ERC20, ERC20Permit, Ownable, ReentrancyGuard, Pausable {
    using Math for uint256;

    // Custom Errors
    error ICONotStarted();
    error ICOEnded();
    error ICONotEnded();
    error InvalidPhase();
    error PhaseNotActive();
    error InsufficientTokensRemaining();
    error InvalidAmount();
    error InvalidPrice();
    error InsufficientFunds();
    error NotWhitelisted();
    error ExceedsIndividualCap();
    error ExceedsPhaseCap();
    error TokensNotVested();
    error NoTokensToWithdraw();
    error WithdrawalFailed();
    error InvalidAddress();
    error InvalidTimestamp();

    // Structs
    struct Phase {
        uint256 startTime;
        uint256 endTime;
        uint256 price; // Price per token in wei
        uint256 tokensAvailable;
        uint256 tokensSold;
        uint256 individualCap; // Max tokens per individual in this phase
        bool requiresWhitelist;
        bool isActive;
    }

    struct Purchase {
        uint256 amount;
        uint256 price;
        uint256 timestamp;
        uint256 phase;
    }

    struct VestingSchedule {
        uint256 totalAmount;
        uint256 releasedAmount;
        uint256 startTime;
        uint256 duration;
        uint256 cliffDuration;
    }

    // State Variables
    uint256 public constant TOTAL_SUPPLY = 1000000000 * 10**18; // 1 billion tokens
    uint256 public constant ICO_SUPPLY = 400000000 * 10**18; // 40% for ICO
    uint256 public constant TEAM_SUPPLY = 200000000 * 10**18; // 20% for team
    uint256 public constant RESERVE_SUPPLY = 400000000 * 10**18; // 40% reserve

    uint256 public immutable icoStartTime;
    uint256 public immutable icoEndTime;
    uint256 public totalRaised;
    uint256 public currentPhase;
    
    address public treasury;
    bool public icoFinalized;
    bool public vestingEnabled;

    // Mappings
    mapping(uint256 => Phase) public phases;
    mapping(address => bool) public whitelist;
    mapping(address => Purchase[]) public userPurchases;
    mapping(address => uint256) public userTotalPurchased;
    mapping(address => VestingSchedule) public vestingSchedules;
    mapping(address => bool) public blacklist;

    // Events
    event PhaseCreated(uint256 indexed phaseId, uint256 startTime, uint256 endTime, uint256 price);
    event PhaseUpdated(uint256 indexed phaseId, uint256 price, uint256 tokensAvailable);
    event TokensPurchased(address indexed buyer, uint256 amount, uint256 price, uint256 phase);
    event WhitelistUpdated(address indexed user, bool status);
    event BlacklistUpdated(address indexed user, bool status);
    event VestingScheduleCreated(address indexed beneficiary, uint256 amount, uint256 startTime, uint256 duration);
    event TokensVested(address indexed beneficiary, uint256 amount);
    event FundsWithdrawn(address indexed to, uint256 amount);
    event ICOFinalized(uint256 totalRaised, uint256 tokensSold);
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);

    // Modifiers
    modifier onlyDuringICO() {
        if (block.timestamp < icoStartTime) revert ICONotStarted();
        if (block.timestamp > icoEndTime) revert ICOEnded();
        _;
    }

    modifier onlyAfterICO() {
        if (block.timestamp <= icoEndTime) revert ICONotEnded();
        _;
    }

    modifier validAddress(address _address) {
        if (_address == address(0)) revert InvalidAddress();
        _;
    }

    modifier notBlacklisted(address _address) {
        require(!blacklist[_address], "Address is blacklisted");
        _;
    }

    modifier phaseExists(uint256 _phaseId) {
        if (phases[_phaseId].startTime == 0) revert InvalidPhase();
        _;
    }

    constructor(
        address _treasury,
        uint256 _icoStartTime,
        uint256 _icoEndTime
    ) 
        ERC20("SmartTokens", "SMART")
        ERC20Permit("SmartTokens")
        Ownable(msg.sender)
        validAddress(_treasury)
    {
        if (_icoStartTime >= _icoEndTime) revert InvalidTimestamp();
        if (_icoStartTime < block.timestamp) revert InvalidTimestamp();

        treasury = _treasury;
        icoStartTime = _icoStartTime;
        icoEndTime = _icoEndTime;

        // Mint tokens to contract for ICO
        _mint(address(this), ICO_SUPPLY);
        
        // Mint team and reserve tokens to owner (to be distributed later)
        _mint(owner(), TEAM_SUPPLY + RESERVE_SUPPLY);

        // Create initial phase
        _createPhase(0, _icoStartTime, _icoEndTime, 0.001 ether, ICO_SUPPLY, ICO_SUPPLY, false);
    }

    // Admin Functions
    function createPhase(
        uint256 _phaseId,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _price,
        uint256 _tokensAvailable,
        uint256 _individualCap,
        bool _requiresWhitelist
    ) external onlyOwner {
        _createPhase(_phaseId, _startTime, _endTime, _price, _tokensAvailable, _individualCap, _requiresWhitelist);
    }

    function _createPhase(
        uint256 _phaseId,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _price,
        uint256 _tokensAvailable,
        uint256 _individualCap,
        bool _requiresWhitelist
    ) internal {
        if (_startTime >= _endTime) revert InvalidTimestamp();
        if (_price == 0) revert InvalidPrice();
        if (_tokensAvailable == 0) revert InvalidAmount();

        phases[_phaseId] = Phase({
            startTime: _startTime,
            endTime: _endTime,
            price: _price,
            tokensAvailable: _tokensAvailable,
            tokensSold: 0,
            individualCap: _individualCap,
            requiresWhitelist: _requiresWhitelist,
            isActive: true
        });

        emit PhaseCreated(_phaseId, _startTime, _endTime, _price);
    }

    function updatePhase(
        uint256 _phaseId,
        uint256 _price,
        uint256 _tokensAvailable,
        uint256 _individualCap,
        bool _isActive
    ) external onlyOwner phaseExists(_phaseId) {
        Phase storage phase = phases[_phaseId];
        
        if (_price > 0) {
            phase.price = _price;
        }
        if (_tokensAvailable > 0) {
            phase.tokensAvailable = _tokensAvailable;
        }
        if (_individualCap > 0) {
            phase.individualCap = _individualCap;
        }
        
        phase.isActive = _isActive;

        emit PhaseUpdated(_phaseId, phase.price, phase.tokensAvailable);
    }

    function setCurrentPhase(uint256 _phaseId) external onlyOwner phaseExists(_phaseId) {
        currentPhase = _phaseId;
    }

    function updateWhitelist(address[] calldata _users, bool _status) external onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            whitelist[_users[i]] = _status;
            emit WhitelistUpdated(_users[i], _status);
        }
    }

    function updateBlacklist(address[] calldata _users, bool _status) external onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            blacklist[_users[i]] = _status;
            emit BlacklistUpdated(_users[i], _status);
        }
    }

    function setTreasury(address _newTreasury) external onlyOwner validAddress(_newTreasury) {
        address oldTreasury = treasury;
        treasury = _newTreasury;
        emit TreasuryUpdated(oldTreasury, _newTreasury);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function finalizeICO() external onlyOwner onlyAfterICO {
        require(!icoFinalized, "ICO already finalized");
        
        icoFinalized = true;
        
        // Burn remaining tokens
        uint256 remainingTokens = balanceOf(address(this));
        if (remainingTokens > 0) {
            _burn(address(this), remainingTokens);
        }

        emit ICOFinalized(totalRaised, ICO_SUPPLY - remainingTokens);
    }

    function withdrawFunds(uint256 _amount) external onlyOwner nonReentrant {
        if (_amount > address(this).balance) revert InsufficientFunds();
        
        (bool success, ) = treasury.call{value: _amount}("");
        if (!success) revert WithdrawalFailed();
        
        emit FundsWithdrawn(treasury, _amount);
    }

    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = treasury.call{value: balance}("");
        if (!success) revert WithdrawalFailed();
        
        emit FundsWithdrawn(treasury, balance);
    }

    // User Functions
    function buyTokens() external payable onlyDuringICO whenNotPaused nonReentrant notBlacklisted(msg.sender) {
        _buyTokens();
    }

    function _buyTokens() internal {
        if (msg.value == 0) revert InvalidAmount();
        
        Phase storage phase = phases[currentPhase];
        if (!phase.isActive) revert PhaseNotActive();
        if (block.timestamp < phase.startTime || block.timestamp > phase.endTime) revert PhaseNotActive();
        
        if (phase.requiresWhitelist && !whitelist[msg.sender]) {
            revert NotWhitelisted();
        }

        uint256 tokenAmount = (msg.value * 10**decimals()) / phase.price;
        
        if (tokenAmount == 0) revert InvalidAmount();
        if (phase.tokensSold + tokenAmount > phase.tokensAvailable) {
            revert InsufficientTokensRemaining();
        }
        
        if (phase.individualCap > 0 && userTotalPurchased[msg.sender] + tokenAmount > phase.individualCap) {
            revert ExceedsIndividualCap();
        }

        // Update state
        phase.tokensSold += tokenAmount;
        userTotalPurchased[msg.sender] += tokenAmount;
        totalRaised += msg.value;

        // Record purchase
        userPurchases[msg.sender].push(Purchase({
            amount: tokenAmount,
            price: phase.price,
            timestamp: block.timestamp,
            phase: currentPhase
        }));

        // Transfer tokens
        _transfer(address(this), msg.sender, tokenAmount);

        emit TokensPurchased(msg.sender, tokenAmount, phase.price, currentPhase);
    }

    // Vesting Functions
    function createVestingSchedule(
        address _beneficiary,
        uint256 _amount,
        uint256 _startTime,
        uint256 _duration,
        uint256 _cliffDuration
    ) external onlyOwner validAddress(_beneficiary) {
        require(_amount > 0, "Amount must be greater than 0");
        require(_duration > 0, "Duration must be greater than 0");
        require(_cliffDuration <= _duration, "Cliff duration cannot exceed total duration");
        require(vestingSchedules[_beneficiary].totalAmount == 0, "Vesting schedule already exists");

        vestingSchedules[_beneficiary] = VestingSchedule({
            totalAmount: _amount,
            releasedAmount: 0,
            startTime: _startTime,
            duration: _duration,
            cliffDuration: _cliffDuration
        });

        emit VestingScheduleCreated(_beneficiary, _amount, _startTime, _duration);
    }

    function releaseVestedTokens() external nonReentrant {
        VestingSchedule storage schedule = vestingSchedules[msg.sender];
        if (schedule.totalAmount == 0) revert NoTokensToWithdraw();

        uint256 vestedAmount = _calculateVestedAmount(msg.sender);
        uint256 releasableAmount = vestedAmount - schedule.releasedAmount;
        
        if (releasableAmount == 0) revert TokensNotVested();

        schedule.releasedAmount += releasableAmount;
        _transfer(owner(), msg.sender, releasableAmount);

        emit TokensVested(msg.sender, releasableAmount);
    }

    function _calculateVestedAmount(address _beneficiary) internal view returns (uint256) {
        VestingSchedule memory schedule = vestingSchedules[_beneficiary];
        
        if (block.timestamp < schedule.startTime + schedule.cliffDuration) {
            return 0;
        }
        
        if (block.timestamp >= schedule.startTime + schedule.duration) {
            return schedule.totalAmount;
        }
        
        uint256 timeElapsed = block.timestamp - schedule.startTime;
        return (schedule.totalAmount * timeElapsed) / schedule.duration;
    }

    // View Functions
    function getCurrentPhaseInfo() external view returns (
        uint256 startTime,
        uint256 endTime,
        uint256 price,
        uint256 tokensAvailable,
        uint256 tokensSold,
        uint256 individualCap,
        bool requiresWhitelist,
        bool isActive
    ) {
        Phase memory phase = phases[currentPhase];
        return (
            phase.startTime,
            phase.endTime,
            phase.price,
            phase.tokensAvailable,
            phase.tokensSold,
            phase.individualCap,
            phase.requiresWhitelist,
            phase.isActive
        );
    }

    function getUserPurchases(address _user) external view returns (Purchase[] memory) {
        return userPurchases[_user];
    }

    function getVestedAmount(address _beneficiary) external view returns (uint256) {
        return _calculateVestedAmount(_beneficiary);
    }

    function getReleasableAmount(address _beneficiary) external view returns (uint256) {
        VestingSchedule memory schedule = vestingSchedules[_beneficiary];
        uint256 vestedAmount = _calculateVestedAmount(_beneficiary);
        return vestedAmount - schedule.releasedAmount;
    }

    function getRemainingTokensInPhase(uint256 _phaseId) external view phaseExists(_phaseId) returns (uint256) {
        Phase memory phase = phases[_phaseId];
        return phase.tokensAvailable - phase.tokensSold;
    }

    function getTokenPrice(uint256 _phaseId) external view phaseExists(_phaseId) returns (uint256) {
        return phases[_phaseId].price;
    }

    function isWhitelisted(address _user) external view returns (bool) {
        return whitelist[_user];
    }

    function isBlacklisted(address _user) external view returns (bool) {
        return blacklist[_user];
    }

    // Override functions for pausable functionality
    function _update(address from, address to, uint256 value) internal override whenNotPaused {
        super._update(from, to, value);
    }

    // Fallback function to receive ETH
    receive() external payable {
        if (msg.value > 0) {
            // Check all the conditions inline since we can't use external modifiers
            if (block.timestamp < icoStartTime) revert ICONotStarted();
            if (block.timestamp > icoEndTime) revert ICOEnded();
            if (paused()) revert();
            if (blacklist[msg.sender]) revert();
            
            _buyTokens();
        }
    }
}