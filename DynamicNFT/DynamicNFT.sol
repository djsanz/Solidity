// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// 0x36d74276d9d60351975a62633F2270cdf95618C9
// https://testnets.opensea.io/assets/0x36d74276d9d60351975a62633f2270cdf95618c9/0
// https://rinkeby.rarible.com/token/0x36d74276d9d60351975a62633f2270cdf95618c9:0?tab=details

contract SierraBlockGamesNFT is ERC721, ERC721Enumerable, ERC721URIStorage, AccessControl {
    using Counters for Counters.Counter;

    string public constant WEB = "https://sierrablockgames.es";
    bytes32 public constant ROLE_MINTER = keccak256("ROLE_MINTER");
	bytes32 public constant ROLE_URI = keccak256("ROLE_URI");

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("DynamicNFT", "DynamicNFT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ROLE_MINTER, msg.sender);
        _grantRole(ROLE_URI, msg.sender);
    }

    function safeMint(address to, string memory uri) public onlyRole(ROLE_MINTER) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function setTokenURI(uint256 tokenId, string memory uri) public onlyRole(ROLE_URI) {
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
        _setTokenURI(tokenId, uri);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }
}