// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {LibMallFunctions} from "../libraries/LibNftMall.sol";
import {LibRateLookUp} from "../libraries/LibNftMall.sol";

contract NftMall {
    function sellNFT(
        address _nftAddress,
        uint256 _nftId,
        uint256 _price
    ) external {
        LibMallFunctions._sellNFT(_nftAddress, _nftId, _price);
    }

    // get Unique ID for each good to be sold
    function getYourUniqueId(
        address _nftAddress,
        uint256 _nftId,
        uint256 _nftPrice
    ) external pure returns (bytes32 uniqueId) {
        uniqueId = LibMallFunctions._getUniqueId(
            _nftAddress,
            _nftId,
            _nftPrice
        );
    }

    // Function to buy an NFT with ETH
    function buyNFTWithETH(uint256 _id) external payable {
        LibMallFunctions._buyNFTWithETH(_id);
    }

    // Function to buy an NFT with a supported token
    function buyNFTWithToken(
        uint256 _id,
        address _tokenAddress,
        string calldata _fromToken,
        // uint8 _decimals,
        uint256 _amount
    ) external {
        LibMallFunctions._buyNFTWithToken(
            _id,
            _tokenAddress,
            _fromToken,
            // _decimals,
            _amount
        );
    }

    // Mall Creator Withdrawal dunction
    function _AdminWithdrawal() external {
        LibMallFunctions._AdminWithdrawal();
    }

    function addAggregator(
        string memory _tokenName,
        address _aggregatorAddress
    ) external {
        LibRateLookUp._addAggregator( _tokenName, _aggregatorAddress);
    }

    function deleteAggregator(string calldata _tokenName) external {
        LibRateLookUp._deleteAggregator(_tokenName);
    }

    receive() external payable {}
}
