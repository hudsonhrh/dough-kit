// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IWXDAI {
  function deposit() external payable;
  function withdraw(uint256) external;
}
