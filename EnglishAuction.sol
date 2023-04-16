// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/token/ERC721/utils/ERC721Holder.sol";

contract EnglishAuction {
    address payable public immutable owner;
    address payable public immutable creator;
    uint256 public immutable royaltyPercentage;
    uint256 public immutable start;
    uint256 public immutable end;
    uint256 public currentHighestBid;
    address public currentHighestBidder;
    bool public ended;
    IERC721 public nft;
    uint256 public tokenId; // Add tokenId variable
    bool private _hasFinalized;

    event NewHighestBid(address indexed bidder, uint256 amount);
    event BidOutbid(address indexed outbidBidder, uint256 newHighestBid);
    event AuctionEnded(address indexed winner, uint256 amount);
    event AuctionFinalized(address indexed winner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the auction owner");
        _;
    }
        modifier auctionEnded() {
        require(block.timestamp >= end, "Auction is still ongoing");
        _;
    }

    constructor(
        uint256 _royaltyPercentage,
        uint256 _start,
        uint256 _end,
        address _nftAddress,
        uint256 _tokenId // Add tokenId parameter
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

        // Transfer the NFT to the contract manually
        function transferNFT() external onlyOwner {
            nft.transferFrom(msg.sender, address(this), tokenId);

    }

    function placeBid() external payable {
        require(!ended, "Auction has ended.");
        require(msg.sender != currentHighestBidder, "You are already the highest bidder.");

        if (currentHighestBid == 0) {
            require(msg.value > 0.99 ether, "Bid must be greater than 0.99 ether.");
        } else {
            require(msg.value >= currentHighestBid * 110 / 100, "Bid amount must be at least 10% higher than the current highest bid.");

            // Refund the previous highest bidder
            payable(currentHighestBidder).transfer(currentHighestBid);
        }

        currentHighestBid = msg.value;
        currentHighestBidder = msg.sender;

        emit NewHighestBid(msg.sender, msg.value);
    }

    function endAuction() external onlyOwner {
        require(!ended, "Auction has already ended.");
        require(block.timestamp >= end, "Auction has not ended yet.");

        ended = true;

        emit AuctionEnded(currentHighestBidder, currentHighestBid);

        // Automatically finalize the auction if the owner doesn't do it manually
        finalize();
    }

    function finalize() public {
        require(!_hasFinalized, "Auction has already been finalized."); // Change hasCalledFinalize() to _hasFinalized
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
        nft.transferFrom(address(this), currentHighestBidder, tokenId);

        // Set hasFinalized to true
        _hasFinalized = true;

        emit AuctionFinalized(currentHighestBidder, currentHighestBid);
    }
}
