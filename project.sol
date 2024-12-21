// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTStudyAids is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    struct NFTDetails {
        address creator;
        uint256 royaltyPercentage;
    }

    mapping(uint256 => NFTDetails) public nftDetails;
    mapping(uint256 => address payable) private tokenOwners;

    event NFTMinted(address indexed creator, uint256 tokenId, string tokenURI, uint256 royaltyPercentage);
    event NFTSold(address indexed seller, address indexed buyer, uint256 tokenId, uint256 salePrice);

    // Updated constructor to pass deployer's address to Ownable
    constructor() ERC721("StudyAidNFT", "SAID") Ownable(msg.sender) {}

    function mintNFT(string memory tokenURI, uint256 royaltyPercentage) public returns (uint256) {
        require(royaltyPercentage <= 10, "Royalty cannot exceed 10%");

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        nftDetails[newTokenId] = NFTDetails({
            creator: msg.sender,
            royaltyPercentage: royaltyPercentage
        });

        tokenOwners[newTokenId] = payable(msg.sender);

        emit NFTMinted(msg.sender, newTokenId, tokenURI, royaltyPercentage);
        return newTokenId;
    }

    function purchaseNFT(uint256 tokenId) public payable {
        address payable currentOwner = tokenOwners[tokenId];
        require(currentOwner != address(0), "NFT not found");
        require(msg.value > 0, "Payment must be greater than zero");
        require(msg.sender != currentOwner, "Cannot purchase your own NFT");

        NFTDetails memory details = nftDetails[tokenId];
        uint256 royaltyAmount = (msg.value * details.royaltyPercentage) / 100;
        uint256 sellerAmount = msg.value - royaltyAmount;

        // Pay the creator their royalty
        payable(details.creator).transfer(royaltyAmount);
        // Pay the current owner of the NFT
        currentOwner.transfer(sellerAmount);

        // Transfer ownership of the NFT
        _transfer(currentOwner, msg.sender, tokenId);
        tokenOwners[tokenId] = payable(msg.sender);

        emit NFTSold(currentOwner, msg.sender, tokenId, msg.value);
    }

    function getRoyaltyInfo(uint256 tokenId) public view returns (address, uint256) {
        NFTDetails memory details = nftDetails[tokenId];
        return (details.creator, details.royaltyPercentage);
    }

    function getTokenOwner(uint256 tokenId) public view returns (address) {
        return tokenOwners[tokenId];
    }
}
