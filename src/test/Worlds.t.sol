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


contract WorldsTest is IERC721Receiver, DSTest {
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
    Worlds worlds;

  
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns(bytes4) {
        return this.onERC721Received.selector;
    }

    function setUp() public {
        worlds = new Worlds();
    }

    address[] _whiteList;

    function _seedWhiteList() internal {
        _whiteList.push(address(1));
        _whiteList.push(address(2));
        _whiteList.push(address(3));
        worlds.seedWhitelist(_whiteList);
    }

    function _beginSale() internal {
        worlds.updateStartTime(1650000000);
        cheats.warp(1650000000);
    }


    function testUpdateStartTimeAsOwner() public {
        worlds.updateStartTime(1650000000);
        (, , uint32 newStartTime ) = worlds.saleConfig();
        assertEq(newStartTime, 1650000000);
    }
    
    function testUpdateStartTimeAsNotOwner() public {
        cheats.expectRevert(bytes("Ownable: caller is not the owner"));
        cheats.prank(address(0));
        worlds.updateStartTime(1650000000);
    }

    function testCannotMintBeforeStartTime() public {
        worlds.updateStartTime(1650000000);
        cheats.warp(1649999999);
        (uint64 price, , ) = worlds.saleConfig();
        cheats.expectRevert(abi.encodeWithSignature("BeforeSaleStart()"));
        worlds.mintWorlds{value: price}(1);
    }

    function testCannotMintInsufficientFunds() public {
        _beginSale();
        (uint64 price, ,) = worlds.saleConfig();
        cheats.expectRevert(abi.encodeWithSignature("InsufficientFunds()"));
        worlds.mintWorlds{value: price -1}(1);
    }

    function testCannotMintBeyondMaxSupply() public {
        _beginSale();
        (uint64 price, uint32 maxSupply ,) = worlds.saleConfig();
        uint valueToSend = uint(price) * uint(maxSupply +1);
        cheats.expectRevert(abi.encodeWithSignature("ExceedsMaxSupply()"));
        worlds.mintWorlds{value: valueToSend}(maxSupply + 1);
    }

    function testMintWorlds() public {
        _beginSale();
        (uint64 price ,,) = worlds.saleConfig();
        uint amountToMint = 1;
        assertEq(worlds.balanceOf(address(this)), 0);
        worlds.mintWorlds{value: price}(amountToMint);
        assertEq(worlds.balanceOf(address(this)), amountToMint);
    }

    function testMintWorldsFuzzing(uint16 amount) public {
        (uint64 price, uint32 maxSupply , ) = worlds.saleConfig();
        if (amount > maxSupply) amount = uint16(maxSupply);
        if (amount == 0) amount = 1;

        _beginSale();

        uint valueToSend = uint(price) * uint(amount);

        worlds.mintWorlds{value: valueToSend}(amount);
    }

    function testMintAllWorlds() public {
        _beginSale();
        (uint64 price, uint64 maxSupply,) = worlds.saleConfig();
        uint amountToSend = uint(price) * uint(maxSupply);
        assertEq(worlds.balanceOf(address(this)), 0);
        worlds.mintWorlds{value: amountToSend}(maxSupply);
        assertEq(worlds.balanceOf(address(this)), maxSupply);
    }

    function testTokenURI() public {
         _beginSale();
        (uint64 price, uint64 maxSupply ,) = worlds.saleConfig();
        uint valueToSend = uint(price) * uint(maxSupply);
        worlds.mintWorlds{value: valueToSend}(maxSupply);

        string memory uri = worlds.tokenURI(1);
        assertEq(uri, "ipfs://sup/1");
    }

    function testWithdraw() public {
        _beginSale();
        (uint64 price, uint64 maxSupply ,) = worlds.saleConfig();
        uint valueToSend = uint(price) * uint(maxSupply);
        worlds.mintWorlds{value: valueToSend}(maxSupply);

        assertEq(address(worlds).balance, valueToSend);

        uint balanceBefore = address(this).balance;
        worlds.withdraw();
        uint balanceAfter = address(this).balance;

        assertEq(balanceAfter - balanceBefore, valueToSend);
    }


    function testWithdrawNotOwner() public {
        cheats.expectRevert(bytes("Ownable: caller is not the owner"));
        cheats.prank(address(1));
        worlds.withdraw();
    }


    function testSeedWhitelist() public {
        _seedWhiteList();
        assertEq(worlds.whitelist(address(1)), 2);
        assertEq(worlds.whitelist(address(2)), 2);
        assertEq(worlds.whitelist(address(3)), 2);
    }

    function testCannotMintWhiteListBeforeStartTime() public {
        _seedWhiteList();
        worlds.updateStartTime(1650000000);
        cheats.warp(1649999999);
        cheats.prank(address(1));

        cheats.expectRevert(abi.encodeWithSignature("BeforeSaleStart()"));
        worlds.whitelistMintWorlds(1);
    }


    function testCannotMintWhiteListBeyondMaxSupply() public {
        _beginSale();
        _seedWhiteList();
        (uint64 price , uint64 maxSupply ,) = worlds.saleConfig();
        uint valueToSend = uint(price) * uint(maxSupply);
        worlds.mintWorlds{value: valueToSend}(maxSupply);
        
        cheats.prank(address(1));
        cheats.expectRevert(abi.encodeWithSignature("ExceedsMaxSupply()"));
        worlds.whitelistMintWorlds(1);
    }

    function testCannotMintExceedsWhitelistAllowance() public {
        _beginSale();
        _seedWhiteList();
        cheats.prank(address(1));

        cheats.expectRevert(abi.encodeWithSignature("ExceedsWhitelistAllowance()"));
        worlds.whitelistMintWorlds(3);
    }

    function testWhiteListMintAsWhitelist() public {
        _beginSale();
        _seedWhiteList();
    
        assertEq(worlds.balanceOf(address(1)), 0);

        cheats.prank(address(1));
        worlds.whitelistMintWorlds(2);

        assertEq(worlds.balanceOf(address(1)), 2);

        assertEq(worlds.whitelist(address(1)), 0);
        
    }

    function testWhiteListMintAsNotWhitelist() public {
        _beginSale();
        _seedWhiteList();
    
        assertEq(worlds.balanceOf(address(4)), 0);

        cheats.prank(address(4));
        cheats.expectRevert(abi.encodeWithSignature("ExceedsWhitelistAllowance()"));
        worlds.whitelistMintWorlds(2);
        
    }
  
  
    fallback() external payable {}
    receive() external payable {}
}
