// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../src/contracts/Bread.sol';
import '../../src/contracts/BreadFactory.sol';
import '../../src/contracts/YieldDistributor.sol';
import 'forge-std/Test.sol';

import '@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol';

contract BreadFactoryTest is Test {
  Bread internal breadImpl;
  YieldDistributor internal yieldDistributorImpl;
  ButteredBread internal butteredBreadImpl;
  UpgradeableBeacon internal breadBeacon;
  UpgradeableBeacon internal yieldDistributorBeacon;
  UpgradeableBeacon internal butteredBreadBeacon;
  BreadFactory internal factory;

  // Test addresses
  address internal owner = address(0x12345);
  address internal wxDai = address(0x1111);
  address internal sexyDai = address(0x2222);

  string internal NAME = 'Test Bread';
  string internal SYMBOL = 'TBREAD';
  string internal BB_NAME = 'Test Buttered Bread';
  string internal BB_SYMBOL = 'TBBREAD';

  function setUp() public {
    // Deploy implementations
    breadImpl = new Bread();
    yieldDistributorImpl = new YieldDistributor();
    butteredBreadImpl = new ButteredBread();

    // Setup beacons
    breadBeacon = new UpgradeableBeacon(address(breadImpl), owner);
    yieldDistributorBeacon = new UpgradeableBeacon(address(yieldDistributorImpl), owner);
    butteredBreadBeacon = new UpgradeableBeacon(address(butteredBreadImpl), owner);

    // Deploy factory with beacons
    factory = new BreadFactory(address(breadBeacon), address(yieldDistributorBeacon), address(butteredBreadBeacon));
  }

  function testDeployNewBreadAndDistributor() public {
    // Sample project array for YieldDistributor
    address[] memory projects = new address[](1);
    projects[0] = address(0x1);

    // Sample liquidity pool array for ButteredBread
    address[] memory liquidityPools = new address[](1);
    liquidityPools[0] = address(0x2);

    // Corresponding scaling factors for liquidity pools
    uint256[] memory scalingFactors = new uint256[](1);
    scalingFactors[0] = 150; // Example scaling factor (1.5x)

    // Arbitrary parameters for the YieldDistributor initialization
    uint256 precision = 1e18;
    uint256 minRequiredVotingPower = 1e18;
    uint256 maxPoints = 10;
    uint256 cycleLength = 100;
    uint256 yieldFixedSplitDivisor = 10;
    uint256 lastClaimedBlockNumber = block.number;

    // Deploy Bread, ButteredBread, and YieldDistributor through the factory
    (address breadProxy, address butteredBreadProxy, address yieldDistributorProxy) = factory
      .deployNewBreadAndDistributor(
      NAME,
      SYMBOL,
      BB_NAME,
      BB_SYMBOL,
      owner,
      wxDai,
      sexyDai,
      precision,
      minRequiredVotingPower,
      maxPoints,
      cycleLength,
      yieldFixedSplitDivisor,
      lastClaimedBlockNumber,
      projects,
      liquidityPools,
      scalingFactors
    );

    // Verify Bread proxy address
    assertTrue(breadProxy != address(0), 'Bread proxy should not be zero');

    // Verify ButteredBread proxy address
    assertTrue(butteredBreadProxy != address(0), 'ButteredBread proxy should not be zero');

    // Verify YieldDistributor proxy address
    assertTrue(yieldDistributorProxy != address(0), 'YieldDistributor proxy should not be zero');

    // Interact with Bread proxy
    Bread bread = Bread(breadProxy);
    assertEq(bread.name(), NAME, 'Bread name mismatch');
    assertEq(bread.symbol(), SYMBOL, 'Bread symbol mismatch');
    assertEq(bread.owner(), owner, 'Bread owner mismatch');
    assertEq(address(bread.wxDai()), wxDai, 'wxDai mismatch');
    assertEq(address(bread.sexyDai()), sexyDai, 'sexyDai mismatch');

    // Interact with ButteredBread proxy
    ButteredBread butteredBread = ButteredBread(butteredBreadProxy);
    assertEq(butteredBread.name(), BB_NAME, 'ButteredBread name mismatch');
    assertEq(butteredBread.symbol(), BB_SYMBOL, 'ButteredBread symbol mismatch');
    assertEq(butteredBread.owner(), owner, 'ButteredBread owner mismatch');
    assertEq(butteredBread.scalingFactors(liquidityPools[0]), scalingFactors[0], 'Scaling factor mismatch');
    assertTrue(butteredBread.allowlistedLPs(liquidityPools[0]), 'Liquidity pool not allowlisted');

    // Interact with YieldDistributor proxy
    YieldDistributor yd = YieldDistributor(yieldDistributorProxy);
    assertEq(address(yd.BREAD()), breadProxy, 'YieldDistributor Bread address mismatch');
    assertEq(address(yd.BUTTERED_BREAD()), butteredBreadProxy, 'YieldDistributor ButteredBread address mismatch');
    assertEq(yd.PRECISION(), precision, 'YieldDistributor precision mismatch');
    assertEq(yd.minRequiredVotingPower(), minRequiredVotingPower, 'YieldDistributor min voting power mismatch');
    assertEq(yd.maxPoints(), maxPoints, 'YieldDistributor max points mismatch');
    assertEq(yd.cycleLength(), cycleLength, 'YieldDistributor cycle length mismatch');
    assertEq(yd.yieldFixedSplitDivisor(), yieldFixedSplitDivisor, 'YieldDistributor yield fixed split divisor mismatch');

    // Verify initial projects in YieldDistributor
    (address[] memory currentProjects, uint256[] memory distributions) = yd.getCurrentVotingDistribution();
    assertEq(currentProjects.length, 1, 'Projects length mismatch');
    assertEq(currentProjects[0], projects[0], 'Project address mismatch');
    assertEq(distributions.length, 1, 'Distribution length mismatch');
    assertEq(distributions[0], 0, 'Initial distributions should be zero');

    // Check yield claimer setup on Bread
    assertEq(bread.yieldClaimer(), yieldDistributorProxy, 'Yield claimer not set properly');
  }
}
