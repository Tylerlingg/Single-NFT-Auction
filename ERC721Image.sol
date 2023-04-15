// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.0/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.0/contracts/access/Ownable.sol";

contract FixedImageERC721 is ERC721URIStorage, Ownable {
    uint256 private _tokenCounter;
    string private _baseTokenURI;

    constructor(string memory name, string memory symbol, string memory baseTokenURI) ERC721(name, symbol) {
        _tokenCounter = 0;
        _baseTokenURI = baseTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function mint() public onlyOwner {
        uint256 newItemId = _tokenCounter;
        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, ""); // The base token URI is already set, so we pass an empty string here
        _tokenCounter = _tokenCounter + 1;
    }
}

https://raw.githubusercontent.com/Tylerlingg/Tylerlingg.github.io/main/images/26487FHF.png


