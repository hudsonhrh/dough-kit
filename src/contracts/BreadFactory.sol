// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Bread} from './Bread.sol';
import {YieldDistributor} from './YieldDistributor.sol';
import '@oz/proxy/beacon/BeaconProxy.sol';
import {IERC20} from '@oz/token/ERC20/IERC20.sol';

contract BreadFactory {
  address public breadBeacon;
  address public yieldDistributorBeacon;

  event DeployedBreadAndDistributor(address breadProxy, address yieldDistributorProxy, address owner);

  constructor(address _breadBeacon, address _yieldDistributorBeacon) {
    breadBeacon = _breadBeacon;
    yieldDistributorBeacon = _yieldDistributorBeacon;
  }

  function deployNewBreadAndDistributor(
    string memory _name,
    string memory _symbol,
    address _owner,
    address _wxDai,
    address _sexyDai,
    address _butteredBread,
    uint256 _precision,
    uint256 _minRequiredVotingPower,
    uint256 _maxPoints,
    uint256 _cycleLength,
    uint256 _yieldFixedSplitDivisor,
    uint256 _lastClaimedBlockNumber,
    address[] memory _projects
  ) external returns (address breadProxy, address yieldDistributorProxy) {
    // Deploy Bread proxy
    breadProxy = address(
      new BeaconProxy(
        breadBeacon, abi.encodeWithSelector(Bread.initialize.selector, _name, _symbol, _owner, _wxDai, _sexyDai)
      )
    );

    // Deploy YieldDistributor proxy
    yieldDistributorProxy = address(
      new BeaconProxy(
        yieldDistributorBeacon,
        abi.encodeWithSelector(
          YieldDistributor.initialize.selector,
          breadProxy,
          _butteredBread,
          _precision,
          _minRequiredVotingPower,
          _maxPoints,
          _cycleLength,
          _yieldFixedSplitDivisor,
          _lastClaimedBlockNumber,
          _projects
        )
      )
    );

    // set bread yieldClaimer if needed
    Bread(breadProxy).setYieldClaimer(yieldDistributorProxy);

    emit DeployedBreadAndDistributor(breadProxy, yieldDistributorProxy, _owner);
  }
}
