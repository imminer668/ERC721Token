// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarketplace is Ownable {
    IERC20 public erc20Contract;
    IERC721 public nftContract;

    event NFTListed(
        uint256 indexed tokenId,
        address indexed seller,
        uint256 price
    );
    event NFTSold(
        uint256 indexed tokenId,
        address indexed buyer,
        uint256 price
    );
    //error deposit eth too few tips
    error AmountTooLow(uint256 eth);

    event WthdrawEthEvent(address indexed _address, uint256 amount);
    error invalidAddress(address _owner);
    error transferFailed(address _address);

    constructor(
        address _owner,
        address token,
        address nft
    ) Ownable(_owner) {
        erc20Contract = IERC20(token);
        nftContract = IERC721(nft);
    }

    struct Listing {
        uint256 tokenId; //id
        address seller; //拥有者
        uint256 price; // 以wei为单位
        bool active; //是否活跃
    }
    mapping(uint256 => Listing) public lists;

    //上架
    function listNFT(uint256 _tokenId, uint256 _price) public {
        require(
            nftContract.ownerOf(_tokenId) == msg.sender,
            "You are not the owner of this NFT"
        );
        //require(msg.value >= listingFee, "Insufficient listing fee");
        lists[_tokenId] = Listing({
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            active: true
        });

        emit NFTListed(_tokenId, msg.sender, _price);
    }

    function buyNFT(uint256 _tokenId, uint256 _price) public {
        Listing storage listing = lists[_tokenId];
        require(listing.active, "Listing is not active");
        require(_price >= listing.price, "Incorrect payment amount");
        erc20Contract.transferFrom(msg.sender, listing.seller, _price);
        nftContract.transferFrom(listing.seller, msg.sender, listing.tokenId);
        listing.active = false;

        emit NFTSold(listing.tokenId, msg.sender, listing.price);
    }

    function withdrawEth(address payable _recipient, uint256 _amount)
        public
        onlyOwner
    {
        if (_recipient == address(0)) revert invalidAddress(address(0));
        if (_amount == 0 || _amount > address(this).balance)
            revert AmountTooLow(_amount);

        (bool success, ) = _recipient.call{value: _amount}("");
        if (!success) revert transferFailed(_recipient);
        emit WthdrawEthEvent(_recipient, _amount);
    }

    receive() external payable {}
}
