// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Auction {
    address internal auction_owner;
    uint256 public auction_start;
    uint256 public auction_end;
    uint256 public highestBid;
    address public highestBidder;
    uint256 private _tokenId;
    address private _creatorsAddress;
    IERC721 private _token;

    enum AuctionState {CANCELLED, STARTED}

    AuctionState public state;

    modifier an_ongoing_auction() {
        require(block.timestamp <= auction_end, "Auction has ended");
        require(state == AuctionState.STARTED, "Auction is not active");
        _;
    }

    modifier only_owner() {
        require(msg.sender == auction_owner, "Only the owner can call this function");
        _;
    }

    constructor(
        uint256 tokenId,
        address tokenAddress,
        uint256 endTime,
        address creatorsAddress
    ) {
        require(endTime > block.timestamp, "Auction end time should be in the future");

        auction_owner = msg.sender;
        _tokenId = tokenId;
        _token = IERC721(tokenAddress);
        auction_start = block.timestamp;
        auction_end = endTime;
        _creatorsAddress = creatorsAddress;

        // Transfer NFT from owner to contract
        _token.transferFrom(auction_owner, address(this), _tokenId);

        state = AuctionState.STARTED;
    }

    function bid() public payable an_ongoing_auction returns (bool) {
        require(msg.value > highestBid, "Bid amount should be higher than the current highest bid");
        require(msg.sender != auction_owner, "Owner can't bid");

        // Refund the previous highest bidder
        if (highestBidder != address(0)) {
            payable(highestBidder).transfer(highestBid);
        }

        highestBid = msg.value;
        highestBidder = msg.sender;

        return true;
    }

    function end_auction() public only_owner an_ongoing_auction returns (bool) {
        require(highestBidder != address(0), "No bids placed");

        state = AuctionState.CANCELLED;
        auction_end = block.timestamp;

        uint256 creatorsCut = (highestBid * 10) / 100;
        uint256 auctionOwnersCut = highestBid - creatorsCut;

        // Send 10% to the creator's address
        payable(_creatorsAddress).transfer(creatorsCut);

        // Send the remaining amount to the auction owner
        payable(auction_owner).transfer(auctionOwnersCut);

        // Transfer NFT to the highest bidder
        _token.transferFrom(address(this), highestBidder, _tokenId);

        return true;
    }
}

