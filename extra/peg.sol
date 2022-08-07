// rabbit hole token pegging contract
//
// The pegging contract is a smart contract that allows you to peg tokens to other tokens.
//SPDX-License-Identifier: None
pragma solidity ^0.8.0;

contract PeggingToken {
    using SafeMath for uint256;
    // using Ownable;
    using AggregatorV3Interface internal priceFeed;
    
    event Peg(address indexed tokenA, address indexed tokenB, uint256 amountA, uint256 amountB, uint256 liquidity);

    function getReserves() public view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) {
        return (reserve0, reserve1, blockTimestampLast);
    }

    function getReserve0() public view returns (uint112 reserve0) {
        return reserve0;
    }

    function getReserve1() public view returns (uint112 reserve1) {
        return reserve1;
    }

    function getBlockTimestampLast() public view returns (uint32 blockTimestampLast) {
        return blockTimestampLast;
    }

    function getLiquidity() public view returns (uint256 liquidity) {
        return liquidity;
    }

    priceFeed = AggregatorV3Interface(address(0x0));

    function setPriceFeed(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function getPriceFeed() public view returns (address priceFeed) {
        return priceFeed;
    }


    // pegging token to usd

    function getCurrentPrice() public view returns (uint256 currentPrice) {
        return priceFeed.getCurrentPrice();
    }

    function getCurrentPriceInUSD() public view returns (uint256 currentPriceInUSD) {
        return priceFeed.getCurrentPriceInUSD();
    }


}

