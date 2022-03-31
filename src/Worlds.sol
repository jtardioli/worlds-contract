// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "lib/ERC721A.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "solmate/utils/ReentrancyGuard.sol";

error InsufficientFunds();
error ExceedsMaxSupply();
error BeforeSaleStart();
error FailedTransfer();
error ExceedsWhitelistAllowance();
error CannotReduceMaxSupply();
error CannotReduceEpoch();


/// @author https://github.com/jtardioli
contract Worlds is ERC721A, Ownable, ReentrancyGuard {

  struct SaleConfig {
    uint64 price;
    uint32 maxSupply;
    uint32 startTime;
  }

  SaleConfig public saleConfig;

  mapping(address => uint) public whitelist;



  string private baseUri = '';

  constructor() ERC721A("Worlds", "WLD") {
    saleConfig.price = 0.01 ether;
    saleConfig.maxSupply = 111;
    saleConfig.startTime = 1650844800; // April 25, 2020 - 12am
  }

  function mintWorlds(uint _amount) external payable {
    SaleConfig memory config = saleConfig;
    uint _price = uint(config.price);
    uint _maxSupply = uint(config.maxSupply);
    uint _startTime = uint(config.startTime);

    if(_price * _amount != msg.value) revert InsufficientFunds();
    if(_currentIndex + _amount > _maxSupply) revert ExceedsMaxSupply();
    if (block.timestamp < _startTime) revert BeforeSaleStart();

    _safeMint(msg.sender, _amount);
  }

  function whitelistMintWorlds(uint _amount) external payable nonReentrant {
    SaleConfig memory config = saleConfig;
    uint _maxSupply = uint(config.maxSupply);
    uint _startTime = uint(config.startTime);

    if(_currentIndex + _amount > _maxSupply) revert ExceedsMaxSupply();
    if (block.timestamp < _startTime) revert BeforeSaleStart();
    if (_amount > whitelist[msg.sender]) revert ExceedsWhitelistAllowance();

    whitelist[msg.sender] -= _amount;
    _safeMint(msg.sender, _amount);
  }
  
  function seedWhitelist(address[] calldata addresses) 
    external 
    onlyOwner
  {
    // Overflow impossible
    unchecked {
      for (uint256 i = 0; i < addresses.length; ++i) {
        whitelist[addresses[i]] = 3;
      }
    }

  }
   
  function setBaseUri(string calldata _baseUri) external onlyOwner {
    baseUri = _baseUri;
  }

  // Todo needs to be unique for each one
  function tokenURI(uint _tokenId) public view override returns (string memory) {
    if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();
    return baseUri;
  }

  function updateStartTime(uint32 _startTime) external onlyOwner {
    saleConfig.startTime = _startTime;
  }


  function withdraw() public onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    if (!success) revert FailedTransfer();
  }


}
