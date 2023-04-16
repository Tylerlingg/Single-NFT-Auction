// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract EnglishAuction is ERC721Holder, ReentrancyGuard {
    address payable public immutable owner;
    address payable public immutable creator;
    uint256 public immutable royaltyPercentage;
    uint256 public immutable start;
    uint256 public immutable end;
    uint256 public currentHighestBid;
    address public currentHighestBidder;
    bool public ended;
    IERC721 public nft;
    uint256 public tokenId;
    bool private _hasFinalized;

    event NewHighestBid(address indexed bidder, uint256 amount);
    event BidOutbid(address indexed outbidBidder, uint256 newHighestBid);
    event AuctionEnded(address indexed winner, uint256 amount);
    event AuctionFinalized(address indexed winner, uint256 amount);
    event NFTTransferred(address indexed from, address indexed to, uint256 indexed tokenId);

    constructor (
        uint256 _royaltyPercentage,
        uint256 _start,
        uint256 _end,
        address _nftAddress,
        uint256 _tokenId
    ) {
        require(_start > block.timestamp, "Start time must be in the future.");
        require(_end > _start, "End time must be after start time.");

        owner = payable(msg.sender);
        creator = payable(msg.sender);

        royaltyPercentage = _royaltyPercentage;
        start = _start;
        end = _end;
        nft = IERC721(_nftAddress);
        tokenId = _tokenId;
    }
      modifier onlyNotTransferred() {
        require(nft.ownerOf(tokenId) != address(this), "NFT already transferred");
        _;
    }

    function transferNFT() external onlyOwner onlyNotTransferred {
        address from = nft.ownerOf(tokenId);
        nft.transferFrom(from, address(this), tokenId);
        emit NFTTransferred(from, address(this), tokenId);
    } 

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the auction owner");
        _;
    }
    modifier auctionEnded() {
        require(block.timestamp >= end, "Auction is still ongoing");
        _;
    }

    modifier onlyBefore(uint _time) {
        require(block.timestamp < _time, "Operation not allowed after the specified time");
        _;
    }

    modifier onlyNotOwner() {
        require(msg.sender != owner, "Operation not allowed for the contract owner");
        _;
    }

    function placeBid() external payable nonReentrant onlyBefore(end) onlyNotOwner {
    require(msg.sender != address(0), "Bidder address must not be the zero address");
    require(msg.value > currentHighestBid, "Bid too low.");

    uint256 refundAmount = 0;
    if (currentHighestBid != 0) {
        refundAmount = currentHighestBid;
        payable(currentHighestBidder).transfer(refundAmount);
    }

    currentHighestBid = msg.value;
    currentHighestBidder = msg.sender;

    emit NewHighestBid(msg.sender, msg.value);

    // Refund any excess amount to the bidder
    if (refundAmount > 0) {
        uint256 excessAmount = msg.value - refundAmount;
        if (excessAmount > 0) {
            payable(currentHighestBidder).transfer(excessAmount);
        }
    }
}


    function endAuction() external onlyOwner() {
        require(!ended, "Auction has already ended.");
        require(block.timestamp >= end, "Auction has not ended yet.");

        ended = true;

        emit AuctionEnded(currentHighestBidder, currentHighestBid);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) 
    public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    function getCurrentHighestBid() public view returns (uint256) {
    return currentHighestBid;
    }

    function getCurrentHighestBidder() public view returns (address) {
    return currentHighestBidder;
    }

    function getAuctionEndTime() public view returns (uint256) {
    return end;
    }

    function finalize() public onlyOwner nonReentrant auctionEnded {
        require(!_hasFinalized, "Auction has already been finalized.");
        require(ended, "Auction has not ended yet.");

        // Calculate the royalty amount
        uint256 royaltyAmount = (currentHighestBid * royaltyPercentage) / 100;

        // Send the royalty amount to the creator
        creator.transfer(royaltyAmount);

        // Calculate the remaining total
        uint256 remainingTotal = currentHighestBid - royaltyAmount;

        // Send remaining funds to owner
        owner.transfer(remainingTotal);

        // Transfer the NFT to the winner
        nft.safeTransferFrom(address(this), currentHighestBidder, tokenId);

        // Set hasFinalized to true
        _hasFinalized = true;

        emit AuctionFinalized(currentHighestBidder, currentHighestBid);
    }
}
