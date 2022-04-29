// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "ds-test/test.sol";
import "../Worlds.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import "lib/PBRMath.sol";

// Why 2 expect reverts
interface CheatCodes {
  function prank(address) external;
  function expectRevert(bytes4) external;
  function expectRevert(bytes memory) external;
  function warp(uint256) external;
}


contract WorldsTest is DSTest {
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
    Worlds worlds;

    // what does this do
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


    // is the default address the owner? 
    function testUpdateStartTimeAsOwner() public {
        worlds.updateStartTime(1650000000);
        (, , uint32 newStartTime ) = worlds.saleConfig();
        assertEq(newStartTime, 1650000000);
    }
    
    function testUpdateStartTimeAsNotOwner() public {
        // Where does this string come from
        cheats.expectRevert(bytes("Ownable: caller is not the owner"));
        cheats.prank(address(0));
        worlds.updateStartTime(1650000000);
    }

    function testCannotMintBeforeStartTime() public {
        worlds.updateStartTime(1650000000);
        cheats.warp(1649999999);
        (uint64 price, , ) = worlds.saleConfig();
        // wut abi encoded
        cheats.expectRevert(abi.encodeWithSignature("BeforeSaleStart()"));
        //what is this syntax
        worlds.mintWorlds{value: price -1}(1);
    }
  
}
