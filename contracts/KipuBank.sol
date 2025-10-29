// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title KipuBank - A secure personal vault for ETH with deposit and withdrawal limits.
/// @author Kipu Team
/// @notice Users can deposit ETH into a personal vault and withdraw up to a fixed limit per transaction.
/// The contract enforces a global deposit cap and tracks user activity.
contract KipuBank {
    /// @notice Maximum total amount that can be deposited by a single user (1 ETH).
    uint256 public constant bankCap = 1 ether;

    /// @notice Maximum amount that can be withdrawn in a single transaction.
    /// Set at deployment and immutable thereafter.
    uint256 public immutable withdrawLimit;

    /// @notice Struct to track user activity: total deposited amount, number of deposits, and number of withdrawals.
    struct Total {
        uint256 depositsAmount;
        uint256 depositsQtt;
        uint256 withdrawsQtt;
    }

    /// @notice Maps each user address to their activity totals.
    mapping(address => Total) public totals;

    /// @notice Maps each user address to their current available balance.
    mapping(address => uint256) public funds;

    /// @notice Reentrancy guard lock.
    bool private locked;

    /// @notice Emitted when a user successfully deposits ETH.
    /// @param user Address of the depositor.
    /// @param amount Amount deposited in wei.
    event Deposited(address indexed user, uint256 amount);

    /// @notice Emitted when a user successfully withdraws ETH.
    /// @param user Address of the withdrawer.
    /// @param amount Amount withdrawn in wei.
    event Withdrawn(address indexed user, uint256 amount);

    /// @notice Thrown when a deposit or withdrawal amount is zero.
    error ZeroAmount();

    /// @notice Thrown when a deposit would exceed the bank cap or a withdrawal exceeds the limit.
    error AboveLimit();

    /// @notice Thrown when a user tries to withdraw but has no funds.
    error NoFund();

    /// @notice Thrown if a reentrancy attack is detected.
    error ReentrancyDetected();

    /// @notice Prevents reentrancy by locking during external calls.
    modifier noReentrancy() {
        if (locked) revert ReentrancyDetected();
        locked = true;
        _;
        locked = false;
    }

    /// @notice Constructor to set the withdrawal limit at deployment.
    /// @param _withdrawLimit Maximum amount allowed per withdrawal (e.g., 0.1 ether).
    constructor(uint256 _withdrawLimit) {
        if (_withdrawLimit == 0) revert ZeroAmount();
        if (_withdrawLimit > bankCap) revert AboveLimit();
        withdrawLimit = _withdrawLimit;
    }

    /// @notice Allows a user to deposit ETH into their personal vault.
    /// @dev Reverts if amount is zero or would exceed the bankCap.
    /// Emits a Deposited event on success.
    /// @custom:checks-effects-interactions Followed.
    function deposit() external payable {
        if (msg.value == 0) revert ZeroAmount();
        if ((totals[msg.sender].depositsAmount + msg.value) > bankCap) revert AboveLimit();

        _updateTotals(msg.sender, msg.value, true); // true = deposit
        funds[msg.sender] += msg.value;

        emit Deposited(msg.sender, msg.value);
    }

    /// @notice Allows a user to withdraw ETH up to the per-transaction limit.
    /// @dev Reverts if user has no funds or amount exceeds withdrawLimit.
    /// Uses low-level call for ETH transfer and checks success.
    /// Emits a Withdrawn event on success.
    /// @param amount Amount to withdraw (in wei).
    function withdraw(uint256 amount) external noReentrancy {
        if (funds[msg.sender] == 0) revert NoFund();
        if (amount > withdrawLimit) revert AboveLimit();

        funds[msg.sender] -= amount;
        _updateTotals(msg.sender, amount, false); // false = withdrawal

        (bool ok,) = payable(msg.sender).call{value: amount}("");
        require(ok, "transfer failed");

        emit Withdrawn(msg.sender, amount);
    }

    /// @notice Returns comprehensive statistics for a user.
    /// @param user Address of the user to query.
    /// @return depositsAmount Total amount deposited (wei).
    /// @return depositsQtt Number of deposits made.
    /// @return withdrawsQtt Number of withdrawals made.
    /// @return currentBalance Current available balance (wei).
    function getUserStats(address user)
        external
        view
        returns (
            uint256 depositsAmount,
            uint256 depositsQtt,
            uint256 withdrawsQtt,
            uint256 currentBalance
        )
    {
        Total memory userTotal = totals[user];
        return (
            userTotal.depositsAmount,
            userTotal.depositsQtt,
            userTotal.withdrawsQtt,
            funds[user]
        );
    }

    /// @notice Private helper to update user activity counters.
    /// @dev Centralizes logic to avoid duplication and ensure consistency.
    /// @param user Address of the user.
    /// @param amount Amount involved in the operation.
    /// @param isDeposit True if deposit, false if withdrawal.
    function _updateTotals(address user, uint256 amount, bool isDeposit) private {
        if (isDeposit) {
            totals[user].depositsAmount += amount;
            totals[user].depositsQtt += 1;
        } else {
            totals[user].withdrawsQtt += 1;
        }
    }
}