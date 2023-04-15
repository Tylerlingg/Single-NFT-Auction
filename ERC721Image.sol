// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

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

    function mint(address to) public onlyOwner {
        uint256 newTokenId = _tokenCounter;
        _safeMint(to, newTokenId);
        _setTokenURI(newTokenId, "");
        _tokenCounter = _tokenCounter + 1;
    }
}
const FixedImageERC721 = artifacts.require("FixedImageERC721");

module.exports = function (deployer) {
  deployer.deploy(FixedImageERC721, "FixedImageToken", "FIT", "https://raw.githubusercontent.com/YourUsername/YourRepoName/branchName/path/to/image.jpg");
};
