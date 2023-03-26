// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

 // NFT struct to represent an NFT for salex`
 struct NFT {
      address seller;
      address nftAddress;
      uint256 nftId;
      uint256 price;
      bool sold;
    }

 struct MarketStorage {
    //the market owner
    address marketOwner;
    // Mapping of NFT ID to the NFT struct
    mapping (uint256 => NFT) nftsForSale;
    // Mapping of supported token addresses to their on-chain value in ETH
    mapping (address => uint256) tokenPricesInETH;
    // mappings to store the onchain aggregator allowed tokens
    mapping (string => address) aggregator;
 }