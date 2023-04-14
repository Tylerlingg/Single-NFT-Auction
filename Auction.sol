// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTAuction {
    address payable public auctionOwner;
    uint256 public auctionEndTime;
    uint256 public highestBid;
    address payable public highestBidder;
    IERC721 public nftToken;
    uint256 public tokenId;
    address payable public creator = payable(0x4C7BEdfA26C744e6bd61CBdF86F3fc4a76DCa073);
    uint256 public constant creatorFeePercentage = 10;
    uint256 public constant minimumStartingBid = 1 ether;
    
    enum AuctionState {
        CANCELLED,
        STARTED
    }
    
    AuctionState public state;

    modifier anOngoingAuction() {
        require(block.timestamp <= auctionEndTime, "Auction has already ended.");
        require(state == AuctionState.STARTED, "Auction is not ongoing.");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == auctionOwner, "Only the auction owner can call this function.");
        _;
    }

    constructor() {
        auctionOwner = payable(0x166963d11ce7Fd4b56b35fE197638D19862fEf92);
        state = AuctionState.CANCELLED;
    }

    function startAuction(uint256 _endTime, address _nftAddress, uint256 _tokenId) external onlyOwner {
        require(state == AuctionState.CANCELLED, "Please finish the ongoing auction first.");
        require(_endTime > block.timestamp, "Auction end time should be in the future.");
        
        auctionEndTime = _endTime;
        nftToken = IERC721(_nftAddress);
        tokenId = _tokenId;
        state = AuctionState.STARTED;
        nftToken.transferFrom(auctionOwner, address(this), tokenId);
    }

    function bid() public payable anOngoingAuction {
        require(msg.value >= minimumStartingBid, "Bid amount must be at least 1 ether.");
        require(msg.value > highestBid, "Bid amount must be higher than the current highest bid.");
        
        // Refund the previous highest bidder
        if (highestBidder != address(0)) {
            highestBidder.transfer(highestBid);
        }
        
        highestBid = msg.value;
        highestBidder = payable(msg.sender);
    }

    function withdraw() public onlyOwner {
        require(block.timestamp > auctionEndTime, "Auction is still ongoing.");
        require(state != AuctionState.CANCELLED, "Auction has been cancelled.");
        
        uint256 creatorFee = (highestBid * creatorFeePercentage) / 100;
        uint256 auctionOwnerProceeds = highestBid - creatorFee;
        
        creator.transfer(creatorFee);
        auctionOwner.transfer(auctionOwnerProceeds);
        
        nftToken.transferFrom(address(this), highestBidder, tokenId);
        
        state = AuctionState.CANCELLED;
        highestBid = 0;
        highestBidder = payable(address(0));
    }

    function cancelAuction() external onlyOwner {
        require(state != AuctionState.CANCELLED, "Auction has already been cancelled.");
        nftToken.transferFrom(address(this), auctionOwner, tokenId);
        state = AuctionState.CANCELLED;
        highestBid = 0;
        highestBidder = payable(address(0));
    }
}


