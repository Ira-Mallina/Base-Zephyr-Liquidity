# Zephyr Liquidity Stash

A robust decentralized liquidity vault engineered for the Base network. The Zephyr Liquidity Stash allows liquidity providers (LPs) to securely lock their assets into time-weighted pools, generating optimized yields while ensuring strict protocol solvency.

## System Mechanics
* **Time-Weighted Yield Curves:** Reward multipliers dynamically increase based on the duration of the asset lock, incentivizing long-term protocol stability over short-term mercenary capital.
* **Flash-Loan Resistance:** Integrates block-delay mechanisms between deposit and withdrawal actions, effectively neutralizing malicious flash-loan yield extraction.
* **Automated Treasury Sweeps:** Platform administration can seamlessly harvest accumulated protocol fees without interacting with user principal deposits.

## Technical Implementation
Compiled with Solidity `0.8.37`. The vault architecture prioritizes gas efficiency, utilizing packed storage slots for user deposit tracking and optimized math libraries for precise yield calculations.
