// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "ds-test/test.sol";
import "../Worlds.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import "lib/PBRMath.sol";


interface CheatCodes {
  function prank(address) external;
  function expectRevert(bytes4) external;
  function expectRevert(bytes memory) external;
  function warp(uint256) external;
}


contract WorldsTest is DSTest {
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
    Worlds worlds;

    function onERC721Recieved(address, address, uint256, bytes memory) public virtual returns(bytes4) {
        return this.onERC721Recieved.selector;
    }

    function setUp() public {
        worlds = new Worlds();
    }

    address [] addresses;
    uint64[] shares;
    address[] whitelistAddresses;
    uint[] mints;

    function _seedWhiteList() internal  { 
        addresses.push(address(1));
        addresses.push(address(2));
        addresses.push(address(3));
        addresses.push(address(4));

        worlds.seedWhitelist(addresses);
    }

    function _beginSale() internal {
        worlds.updateStartTime(1650000000);
        cheats.warp(1650000000);
    }



 
  
}
