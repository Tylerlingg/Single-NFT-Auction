// Assuming you have an instance of web3, an instance of the NFT contract (nftContract), and the auction contract address (auctionContractAddress)

const tokenId = 1; // The token ID of the NFT you want to auction
const fromAddress = "0x..."; // The address of the NFT owner, who is also deploying the auction contract

await nftContract.methods
  .approve(auctionContractAddress, tokenId)
  .send({ from: fromAddress });
