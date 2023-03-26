// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {LibDiamond} from "./LibDiamond.sol";
import "../interfaces/IAggregatorV3Interface.sol";
import {NFT, MarketStorage} from "./LibNftMallData.sol";

/// @title Price Feed
/// @notice This gets the exchange rate of two Tokens

library LibRateLookUp {
    error NotDiamondOwner(address caller, string info);
    error AggregatorExist(string info);
    error InvalidDecimals(string info);
    error TokenNotSupported(string info);


    function _addAggregator(
        string memory _tokenName,
        address _aggregatorAddress
    ) internal {
        MarketStorage storage ds = MarketSlot();
        // require(msg.sender == LibDiamond.diamondStorage().contractOwner, "Only Owner Can Call");
        if (msg.sender != LibDiamond.diamondStorage().contractOwner)
            revert NotDiamondOwner(msg.sender, "Only Owner Can Call");
        if (ds.aggregator[_tokenName] != address(0))
            revert AggregatorExist("Aggregator already exist");
        ds.aggregator[_tokenName] = _aggregatorAddress;
    }

    function _deleteAggregator(string calldata _tokenName) internal {
        MarketStorage storage ds = MarketSlot();
        if (msg.sender != LibDiamond.diamondStorage().contractOwner)
            revert NotDiamondOwner(msg.sender, "Only Owner Can Call");
        if (ds.aggregator[_tokenName] == address(0))
            revert AggregatorExist("Aggregator does NOT exist");
        ds.aggregator[_tokenName] = address(0);
    }

    /// This gets the exchange rate of two tokens
    /// @param _from This is the token you're swapping from
    // / @param _to This is the token you are swapping to
    /// @param _decimals This is the decimal of the token you are swapping to
    function getDerivedPrice(
        string memory _from,
        string memory _to,
        uint8 _decimals
    ) internal view returns (int256) {
        MarketStorage storage ds = MarketSlot();
        if (_decimals < uint8(0) && _decimals <= uint8(18))
            revert InvalidDecimals("Invalid Decimal For Token Swap");
        int256 decimals = int256(10 ** uint256(_decimals));

        (, int256 fromPrice, , , ) = AggregatorV3Interface(ds.aggregator[_from])
            .latestRoundData();

        uint8 fromDecimals = AggregatorV3Interface(ds.aggregator[_from])
            .decimals();

        fromPrice = scalePrice(fromPrice, fromDecimals, _decimals);

        (, int256 toPrice, , , ) = AggregatorV3Interface(ds.aggregator[_to])
            .latestRoundData();

        uint8 toDecimals = AggregatorV3Interface(ds.aggregator[_to]).decimals();

        toPrice = scalePrice(toPrice, toDecimals, _decimals);

        return (fromPrice * decimals) / toPrice;
    }

    function scalePrice(
        int256 _price,
        uint8 _priceDecimals,
        uint8 _decimals
    ) internal pure returns (int256) {
        if (_priceDecimals < _decimals) {
            return _price * int256(10 ** uint256(_decimals - _priceDecimals));
        } else if (_priceDecimals > _decimals) {
            return _price / int256(10 ** uint256(_priceDecimals - _decimals));
        }
        return _price;
    }

    function getSwapTokenPrice(
        string memory _fromToken,
        string memory _toToken,
        uint8 _decimals,
        int256 _amount
    ) internal view returns (int256) {
        MarketStorage storage ds = MarketSlot();
        if (ds.aggregator[_fromToken] == address(0)) revert TokenNotSupported("WE DON'T SUPPORT THIS TOKEN YET!");
        if (ds.aggregator[_toToken] == address(0)) revert TokenNotSupported("WE DON'T SUPPORT THIS TOKEN YET!");
        return _amount * getDerivedPrice(_fromToken, _toToken, _decimals);
    }

    // Returning The Market Storage Slot
    function MarketSlot() internal pure returns (MarketStorage storage ds) {
        bytes32 location = keccak256("the.smallest.dog.barks.the.loudest");
        assembly {
            ds.slot := location
        }
    }
}
