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

    mapping(address => uint256) public escrow;

    event NewHighestBid(address indexed bidder, uint256 amount);
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
        require(msg.value + escrow[msg.sender] > currentHighestBid, "Bid too low.");

        if (currentHighestBid != 0) {
            escrow[currentHighestBidder] += currentHighestBid;
        }

        // Deduct the new highest bid from the bidder's escrow balance
        escrow[msg.sender] = escrow[msg.sender] + msg.value - currentHighestBid;

        currentHighestBid = escrow[msg.sender];
        currentHighestBidder = msg.sender;

        emit NewHighestBid(msg.sender, escrow[msg.sender]);
    }
    function withdraw() external nonReentrant {
        require(ended, "Auction has not ended yet.");
        uint256 amount = escrow[msg.sender];
        require(amount > 0, "No funds to withdraw");

        escrow[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function endAuction() external onlyOwner {
        require(!ended, "Auction has already ended.");
        require(block.timestamp >= end, "Auction has not ended yet.");

        ended = true;

        emit AuctionEnded(currentHighestBidder, currentHighestBid);
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
