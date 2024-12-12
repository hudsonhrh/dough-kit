// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import {Bread} from './Bread.sol';

import {ButteredBread} from './ButteredBread.sol';
import {YieldDistributor} from './YieldDistributor.sol';

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IButteredBread} from 'src/interfaces/IButteredBread.sol';

contract BreadFactory {
  address public breadBeacon;
  address public yieldDistributorBeacon;
  address public butteredBreadBeacon;

  event DeployedBreadAndDistributor(
    address indexed breadProxy, address indexed butteredBreadProxy, address indexed yieldDistributorProxy, address owner
  );

  constructor(address _breadBeacon, address _yieldDistributorBeacon, address _butteredBreadBeacon) {
    breadBeacon = _breadBeacon;
    yieldDistributorBeacon = _yieldDistributorBeacon;
    butteredBreadBeacon = _butteredBreadBeacon;
  }

  /**
   * @notice Deploys new Bread, ButteredBread, and YieldDistributor proxies.
   * @param _breadName Name of the Bread token
   * @param _breadSymbol Symbol of the Bread token
   * @param _bbName Name of the ButteredBread token
   * @param _bbSymbol Symbol of the ButteredBread token
   * @param _owner The owner address of the contracts after deployment
   * @param _wxDai Address of the wxDai token
   * @param _sexyDai Address of the sexyDai token
   * @param _precision Precision for the YieldDistributor calculations
   * @param _minRequiredVotingPower Minimum voting power required in YieldDistributor
   * @param _maxPoints Maximum voting points in YieldDistributor
   * @param _cycleLength Number of blocks in each yield distribution cycle
   * @param _yieldFixedSplitDivisor Divisor for fixed yield split
   * @param _lastClaimedBlockNumber Starting block for yield distribution calculations
   * @param _projects The array of project addresses for YieldDistributor
   * @param _liquidityPools The array of LP token addresses for ButteredBread
   * @param _scalingFactors The scaling factors for each LP token in ButteredBread
   */
  function deployNewBreadAndDistributor(
    string memory _breadName,
    string memory _breadSymbol,
    string memory _bbName,
    string memory _bbSymbol,
    address _owner,
    address _wxDai,
    address _sexyDai,
    uint256 _precision,
    uint256 _minRequiredVotingPower,
    uint256 _maxPoints,
    uint256 _cycleLength,
    uint256 _yieldFixedSplitDivisor,
    uint256 _lastClaimedBlockNumber,
    address[] memory _projects,
    address[] memory _liquidityPools,
    uint256[] memory _scalingFactors
  ) external returns (address breadProxy, address butteredBreadProxy, address yieldDistributorProxy) {
    // 1. Deploy Bread via BeaconProxy
    breadProxy = address(
      new BeaconProxy(
        breadBeacon,
        abi.encodeWithSelector(Bread.initialize.selector, _breadName, _breadSymbol, address(this), _wxDai, _sexyDai)
      )
    );

    // 2. Deploy ButteredBread via BeaconProxy
    // Create the InitData struct to pass into the ButteredBread initialize function
    IButteredBread.InitData memory initData = IButteredBread.InitData({
      breadToken: breadProxy,
      name: _bbName,
      symbol: _bbSymbol,
      liquidityPools: _liquidityPools,
      scalingFactors: _scalingFactors
    });

    butteredBreadProxy =
      address(new BeaconProxy(butteredBreadBeacon, abi.encodeWithSelector(ButteredBread.initialize.selector, initData)));

    // Transfer ownership of ButteredBread to the specified owner
    OwnableUpgradeable(butteredBreadProxy).transferOwnership(_owner);

    // 3. Deploy YieldDistributor via BeaconProxy
    yieldDistributorProxy = address(
      new BeaconProxy(
        yieldDistributorBeacon,
        abi.encodeWithSelector(
          YieldDistributor.initialize.selector,
          breadProxy,
          butteredBreadProxy,
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

    // 4. Set the yieldClaimer on Bread to the YieldDistributor
    Bread(breadProxy).setYieldClaimer(yieldDistributorProxy);

    // 5. Transfer ownership of Bread to the specified owner
    Bread(breadProxy).transferOwnership(_owner);

    emit DeployedBreadAndDistributor(breadProxy, butteredBreadProxy, yieldDistributorProxy, _owner);
  }
}
