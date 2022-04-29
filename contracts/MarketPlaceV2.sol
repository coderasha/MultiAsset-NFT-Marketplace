//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract NFTMarket is ReentrancyGuard {
  using Counters for Counters.Counter;
  using EnumerableSet for EnumerableSet.UintSet;

  // Add the library methods
  Counters.Counter public _itemIds; //total number of items ever created
  Counters.Counter public _itemsSold; //total number of items sold

  // Declare a set state variable
  EnumerableSet.UintSet private curentlyListedIds;

  address payable owner; //owner of the smart contract
  //people have to pay to puy their NFT on this marketplace
  //uint256 listingPrice = 0.025 ether;

  constructor() {
    owner = payable(msg.sender);
  }

  struct MarketItem {
    uint256 itemId;
    address nftContract;
    uint256 tokenId;
    address payable seller; //person selling the nft
    address payable owner; //owner of the nft
    uint256 bidPrice;
    address highestBidder;
    uint256 listingEndTime;
    bool sold;
  }

  //a way to access values of the MarketItem struct above by passing an integer ID
  mapping(uint256 => MarketItem) public idMarketItem;

  //log message (when Item is sold)
  event MarketItemCreated(uint256 indexed itemId, address indexed nftContract, uint256 indexed tokenId, address seller, address owner, uint256 bidPrice, address highestBidder, uint256 listingEndTime, bool sold);


  /// @notice function to create market item
  function createMarketItem(
    address nftContract,
    uint256 tokenId,
    uint256 _endTime
  ) public nonReentrant {
    require(_endTime > block.timestamp,"Bid time is not valid!");

    _itemIds.increment(); //add 1 to the total number of items ever created
    uint256 itemId = _itemIds.current();

    idMarketItem[itemId] = MarketItem(
      itemId,
      nftContract,
      tokenId,
      payable(msg.sender), //address of the seller putting the nft up for sale
      payable(address(0)), //no owner yet (set owner to empty address)
      0, //bid
      address(0), //highestBidder
      _endTime, //listingEndTime
      false //isSold
    );
    curentlyListedIds.add(itemId);
    //transfer ownership of the nft to the contract itself
    IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

    //log this transaction
    emit MarketItemCreated(itemId, nftContract, tokenId, msg.sender, address(0), 0, address(0), _endTime, false);
  }

  function createMarketSale(uint256 _itemId) internal {
    MarketItem memory item = idMarketItem[_itemId];
    uint256 _tokenId = item.tokenId;
    //pay the seller the amount
    payable(item.seller).transfer(item.bidPrice);

    //transfer ownership of the nft from the contract itself to the buyer
    if(item.highestBidder == address(0)){
      IERC721(item.nftContract).transferFrom(address(this), item.seller, _tokenId);
      item.owner = payable(item.seller);
    } 
    else{
      IERC721(item.nftContract).transferFrom(address(this), item.highestBidder, _tokenId);
      item.owner = payable(item.highestBidder); //mark buyer as new owner
    } 

    curentlyListedIds.remove(_itemId);
    
    item.seller = payable(address(0));
    item.sold = true; //mark that it has been sold
    _itemsSold.increment(); //increment the total number of Items sold by 1
    idMarketItem[_itemId] = item;
    //payable(owner).transfer(listingPrice); //pay owner of contract the listing price
  }

  function makeBid(uint256 _itemId) external payable nonReentrant {

    require(idMarketItem[_itemId].seller != address(0), "That item id doesn't exist");
    MarketItem memory item = idMarketItem[_itemId];
    uint256 _bid = msg.value;
    require(item.bidPrice < _bid, "Please make your bid higher than the last bid!");
    require(this.checkItemEndTime(_itemId) > 0, "You can't make a bid on NFT that expired!");

    if (item.highestBidder != address(0)) payable(item.highestBidder).transfer(item.bidPrice);

    item.bidPrice = _bid;
    item.highestBidder = msg.sender;
    idMarketItem[_itemId] = item;
  }

  function checkItemEndTime(uint256 _itemId) external view returns (uint256 _leftTime) {
    require(idMarketItem[_itemId].seller != address(0), "That item id doesn't exist");
    (idMarketItem[_itemId].listingEndTime <= block.timestamp) ? _leftTime = 0 : _leftTime = (idMarketItem[_itemId].listingEndTime - block.timestamp);
  }

  function sendNftToBidder(uint256 _itemId) external nonReentrant {
    if (this.checkItemEndTime(_itemId) == 0) createMarketSale(_itemId);
    else revert("Time has not expired yet! Please wait.");
  }

    function getListedIds() external view returns(uint256[] memory ){
        return curentlyListedIds.values();
    }


  /// @notice total number of items unsold on our platform
  function fetchMarketItems() public view returns (MarketItem[] memory items) {
    uint256 itemCount = _itemIds.current(); //total number of items ever created
    //total number of items that are unsold = total items ever created - total items ever sold
    uint256 unsoldItemCount = _itemIds.current() - _itemsSold.current();
    uint256 currentIndex = 0;
    if(unsoldItemCount == 0) return items;
    items = new MarketItem[](unsoldItemCount);

    //loop through all items ever created
    for (uint256 i = 0; i < itemCount; i++) {
      //get only unsold item
      //check if the item has not been sold
      //by checking if the owner field is empty
      if (idMarketItem[i + 1].owner == address(0)) {
        //yes, this item has never been sold
        uint256 currentId = idMarketItem[i + 1].itemId;
        MarketItem storage currentItem = idMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items; //return array of all unsold items
  }

  /// @notice fetch list of NFTS owned/bought by this user
  function fetchMyNFTs() public view returns (MarketItem[] memory) {
    //get total number of items ever created
    uint256 totalItemCount = _itemIds.current();

    uint256 itemCount = 0;
    uint256 currentIndex = 0;

    for (uint256 i = 0; i < totalItemCount; i++) {
      //get only the items that this user has bought/is the owner
      if (idMarketItem[i + 1].owner == msg.sender) {
        itemCount += 1; //total length
      }
    }

    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint256 i = 0; i < totalItemCount; i++) {
      if (idMarketItem[i + 1].owner == msg.sender) {
        uint256 currentId = idMarketItem[i + 1].itemId;
        MarketItem storage currentItem = idMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }

  /// @notice fetch list of NFTS owned/bought by this user
  function fetchItemsCreated() public view returns (MarketItem[] memory) {
    //get total number of items ever created
    uint256 totalItemCount = _itemIds.current();

    uint256 itemCount = 0;
    uint256 currentIndex = 0;

    for (uint256 i = 0; i < totalItemCount; i++) {
      //get only the items that this user has bought/is the owner
      if (idMarketItem[i + 1].seller == msg.sender) {
        itemCount += 1; //total length
      }
    }

    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint256 i = 0; i < totalItemCount; i++) {
      if (idMarketItem[i + 1].seller == msg.sender) {
        uint256 currentId = idMarketItem[i + 1].itemId;
        MarketItem storage currentItem = idMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }
}
