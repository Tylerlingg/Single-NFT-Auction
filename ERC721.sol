//Simple ERC721 contract that we can use as the NFT contract address for the test portion. 

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract SimpleERC721 is ERC721 {
    constructor() ERC721("SimpleERC721", "SERC721") {}

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }
}
