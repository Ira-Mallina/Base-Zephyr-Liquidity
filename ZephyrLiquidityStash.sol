// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

contract ZephyrLiquidityStash {
    struct StashAccount {
        uint256 balance;
        uint256 lockedUntil;
        uint256 depositCount;
        bool exists;
    }

    address payable public immutable stashKeeper;
    string public protocolName;
    uint256 public ticketPrice;
    uint256 public totalStashedCapital;
    uint256 public currentJackpotPool;
    uint256 public protocolFeePercent; // например, 2 = 2%

    address[] private participants;
    mapping(address => StashAccount) public accounts;
    mapping(address => uint256) public pendingWinnings;

    event StashDeposited(address indexed user, uint256 amount, uint256 lockDuration);
    event TicketPurchased(address indexed buyer, uint256 totalPool);
    event JackpotAwarded(address indexed winner, uint256 prizeAmount);
    event WinningsClaimed(address indexed winner, uint256 amount);
    event StashWithdrawn(address indexed user, uint256 amount);
    event LockExtended(address indexed user, uint256 newLockTime);
    event ProtocolConfigured(string newName, uint256 newTicketPrice, uint256 newFee);
    event EmergencySweepExecuted(address indexed keeper, uint256 amount);

    modifier onlyKeeper() {
        require(msg.sender == stashKeeper, "ZephyrStash: Caller is not keeper");
        _;
    }

    constructor() {
        stashKeeper = payable(msg.sender);
        protocolName = "Zephyr Base Stash v1";
        ticketPrice = 0.00001 ether;
        protocolFeePercent = 2;
    }

    // 1. Депозит в накопительный сейф
    function depositToStash(uint256 lockDurationSeconds) external payable {
        require(msg.value > 0, "ZephyrStash: Positive amount required");

        StashAccount storage acc = accounts[msg.sender];
        uint256 unlock = block.timestamp + lockDurationSeconds;

        if (acc.exists) {
            acc.balance += msg.value;
            if (unlock > acc.lockedUntil) {
                acc.lockedUntil = unlock;
            }
            acc.depositCount++;
        } else {
            accounts[msg.sender] = StashAccount({
                balance: msg.value,
                lockedUntil: unlock,
                depositCount: 1,
                exists: true
            });
        }

        totalStashedCapital += msg.value;
        emit StashDeposited(msg.sender, msg.value, lockDurationSeconds);
    }

    // 2. Покупка билета в пул джекпота
    function buyJackpotTicket() external payable {
        require(msg.value == ticketPrice, "ZephyrStash: Exact ticket price required");

        participants.push(msg.sender);
        currentJackpotPool += msg.value;

        emit TicketPurchased(msg.sender, currentJackpotPool);
    }

    // 3. Розыгрыш джекпота
    function rollJackpotDraw() external onlyKeeper {
        require(participants.length > 0, "ZephyrStash: No participants");
        require(currentJackpotPool > 0, "ZephyrStash: Empty jackpot pool");

        uint256 randomIndex = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.prevrandao, participants.length))
        ) % participants.length;

        address winner = participants[randomIndex];
        uint256 fee = (currentJackpotPool * protocolFeePercent) / 100;
        uint256 prize = currentJackpotPool - fee;

        pendingWinnings[winner] += prize;
        currentJackpotPool = 0;
        delete participants;

        emit JackpotAwarded(winner, prize);
    }

    // 4. Клейм выигранного приза
    function claimJackpotWinnings() external {
        uint256 payout = pendingWinnings[msg.sender];
        require(payout > 0, "ZephyrStash: No prize to claim");

        pendingWinnings[msg.sender] = 0;
        (bool sent, ) = payable(msg.sender).call{value: payout}("");
        require(sent, "ZephyrStash: Payout failed");

        emit WinningsClaimed(msg.sender, payout);
    }

    // 5. Продление времени блокировки сейфа
    function extendStashLock(uint256 extraSeconds) external {
        StashAccount storage acc = accounts[msg.sender];
        require(acc.exists && acc.balance > 0, "ZephyrStash: No active stash");
        require(extraSeconds > 0, "ZephyrStash: Invalid time");

        acc.lockedUntil += extraSeconds;
        emit LockExtended(msg.sender, acc.lockedUntil);
    }

    // 6. Вывод депозита из сейфа
    function withdrawStash(uint256 amount) external {
        StashAccount storage acc = accounts[msg.sender];
        require(acc.exists && acc.balance >= amount, "ZephyrStash: Insufficient balance");
        require(block.timestamp >= acc.lockedUntil, "ZephyrStash: Stash currently locked");

        acc.balance -= amount;
        totalStashedCapital -= amount;

        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "ZephyrStash: Transfer failed");

        emit StashWithdrawn(msg.sender, amount);
    }

    // 7. Обновление параметров протокола
    function configureProtocol(string calldata newName, uint256 newTicketPrice, uint256 newFee) external onlyKeeper {
        require(newFee <= 10, "ZephyrStash: Fee cap is 10%");
        protocolName = newName;
        ticketPrice = newTicketPrice;
        protocolFeePercent = newFee;

        emit ProtocolConfigured(newName, newTicketPrice, newFee);
    }

    // 8. Аварийный вывод остатка казны владельцем
    function emergencyWithdrawal() external onlyKeeper {
        uint256 leftover = address(this).balance - totalStashedCapital;
        require(leftover > 0, "ZephyrStash: Zero non-stashed funds");

        (bool sent, ) = stashKeeper.call{value: leftover}("");
        require(sent, "ZephyrStash: Sweep failed");

        emit EmergencySweepExecuted(stashKeeper, leftover);
    }

    // Чтение информации о сейфе
    function getStashDetails(address user) external view returns (
        uint256 balance,
        uint256 lockedUntil,
        uint256 depositCount,
        bool isUnlocked
    ) {
        StashAccount memory acc = accounts[user];
        return (acc.balance, acc.lockedUntil, acc.depositCount, block.timestamp >= acc.lockedUntil);
    }
}