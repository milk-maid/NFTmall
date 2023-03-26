// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Import ERC20 interfaces for supported tokens
import "lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/interfaces/IERC721.sol";
import {NFT, MarketStorage} from "./LibNftMallData.sol";
import {LibDiamond} from "./LibDiamond.sol";
import {LibRateLookUp} from "./LibRateLookUp.sol";

library LibMallFunctions {
    error NotDiamondOwner(address caller, string info);
    error MallOwner(address mallOwner, string info);

    // Events for when an NFT is put up for sale and when it is sold
    event NFTForSale(
        uint256 indexed id,
        address indexed seller,
        address indexed nftAddress,
        uint256 nftId,
        uint256 price
    );
    event NFTSold(uint256 indexed id, address indexed buyer, uint256 price);

    // Function to put an NFT up for sale
    function _sellNFT(
        address _nftAddress,
        uint256 _nftId,
        uint256 _price
    ) internal {
        require(_price > 0, "Price cannot be zero");

        // Transfer NFT to the contract
        IERC721(_nftAddress).transferFrom(msg.sender, address(this), _nftId);

        MarketStorage storage ds = LibRateLookUp.MarketSlot();

        // Create new NFT struct
        uint256 id = uint256(_getUniqueId(_nftAddress, _nftId, _price));
        IERC721(_nftAddress).approve(ds.marketOwner, _nftId);
        ds.nftsForSale[id] = NFT({
            seller: msg.sender,
            nftAddress: _nftAddress,
            nftId: _nftId,
            price: _price,
            sold: false
        });

        // Emit event
        emit NFTForSale(id, msg.sender, _nftAddress, _nftId, _price);
    }

    // get Unique ID for each good to be sold
    function _getUniqueId(
        address _nftAddress,
        uint256 _nftId,
        uint256 _nftPrice
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_nftAddress, _nftId, _nftPrice));
    }

    // Function to buy an NFT with ETH
    function _buyNFTWithETH(uint256 _id) internal {
        MarketStorage storage ds = LibRateLookUp.MarketSlot();
        NFT storage nft = ds.nftsForSale[_id];
        require(nft.sold == false, "NFT already sold");
        require(msg.value == nft.price, "Incorrect ETH amount sent");

        // Mark NFT as sold
        ds.nftsForSale[_id].sold = true;

        // Transfer NFT to buyer
        IERC721(nft.nftAddress).transferFrom(
            address(this),
            msg.sender,
            nft.nftId
        );

        // Transfer ETH to seller
        (bool success, ) = nft.seller.call{value: nft.price}("");
        require(success, "ETH transfer failed");

        // Emit event
        emit NFTSold(_id, msg.sender, nft.price);
    }

    // Function to buy an NFT with a supported token
    function _buyNFTWithToken(
        uint256 _id,
        address _tokenAddress,
        string calldata _fromToken,
        // uint8 _decimals,
        uint256 _amount
    ) internal {
        MarketStorage storage ds = LibRateLookUp.MarketSlot();
        NFT memory nft = ds.nftsForSale[_id];
        require(nft.sold == false, "NFT already sold");

        // Mark NFT as sold
        ds.nftsForSale[_id].sold = true;

        // Get on-chain value of token in ETH
        // Calculate required ETH amount
        int256 _amountInt = int256(_amount);
        int256 swappedAmount = LibRateLookUp.getSwapTokenPrice(
            _fromToken,
            "ETH",
            18,
            _amountInt
        );

        require(
            uint256(swappedAmount) >= nft.price,
            "amount lesser than TOKEN price"
        );

        // Transfer tokens from buyer to contract
        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);

        // Transfer NFT to buyer
        IERC721(nft.nftAddress).transferFrom(
            address(this),
            msg.sender,
            nft.nftId
        );

        // Transfer ETH to seller
        (bool success, ) = nft.seller.call{value: nft.price}("");
        require(success, "ETH transfer failed");

        // Emit event
        emit NFTSold(_id, msg.sender, nft.price);
    }

    // Admin Taking The Funds For Distribution
    function _AdminWithdrawal() internal {
        if (msg.sender != LibDiamond.diamondStorage().contractOwner)
            revert NotDiamondOwner(msg.sender, "Only Owner Can Call");
        address mallcreator = LibDiamond.diamondStorage().contractOwner;
        (bool success, ) = payable(mallcreator).call{
            value: address(this).balance
        }("");
        if (success == false)
            revert MallOwner(
                mallcreator,
                "Contract fund transfer to mall owner UNSUCCESSFUL!!!"
            );
    }

    // function buyNFTWithUSDT(uint256 _id, address _tokenAddress, uint256 _amount) external {
    //     NFT memory nft = nftsForSale[_id];
    //     require(nft.sold == false, "NFT already sold");

    //     // Get on-chain value of token in ETH
    //     uint256 tokenPriceInETH = tokenPricesInETH[_tokenAddress];
    //     require(tokenPriceInETH > 0, "Token not supported");

    //     // Calculate required ETH amount
    //     uint256 ethAmount = (_amount * tokenPriceInETH) / (10 ** IERC20(_tokenAddress).decimals);

    //     // Transfer tokens from buyer to contract
    //     IERC20(_tokenAddress).transferFrom(msg.sender, address, ethAmount);
    // }
}
