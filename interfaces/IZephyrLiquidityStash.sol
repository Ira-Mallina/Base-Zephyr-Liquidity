// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;
interface IZephyrLiquidityStash {
    function depositLiquidity() external payable;
    function withdrawStash(uint256 stashId) external;
    function claimPendingYield(uint256 stashId) external returns (uint256);
}
