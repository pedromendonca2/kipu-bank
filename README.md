# KipuBank

A secure Ethereum smart contract that acts as a personal vault for ETH, enforcing deposit and withdrawal limits while tracking user activity.

## Overview

KipuBank allows users to:
- Deposit ETH into their personal vault (up to a global cap of **1 ETH per user**).
- Withdraw ETH in transactions limited to a configurable amount (e.g., **0.1 ETH**) set at deployment.
- Track their full activity history via on-chain storage.

The contract follows security best practices including reentrancy protection, custom errors, and the checks-effects-interactions pattern.

## Features

- **Deposit Cap**: Each user can deposit up to **1 ETH** in total.
- **Configurable Withdrawal Limit**: Set once at deployment (e.g., `0.1 ether`), then immutable.
- **Activity Tracking**: Total deposited, deposit count, withdrawal count, and current balance.
- **Security**: Reentrancy guard, safe ETH transfers, and clear error messages.
- **Efficient Queries**: `getUserStats()` returns all user data in one call.

## Requirements

- Solidity ^0.8.30
- Ethereum-compatible wallet (e.g., MetaMask)
- Testnet or mainnet ETH for interaction

## Deployment

The contract requires a withdrawal limit (in wei) during deployment.

Example using Hardhat:
```javascript
const KipuBank = await ethers.getContractFactory("KipuBank");
// Set withdrawal limit to 0.1 ETH
const bank = await KipuBank.deploy(ethers.utils.parseEther("0.1"));
await bank.deployed();
console.log("KipuBank deployed to:", bank.address);