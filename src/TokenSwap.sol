// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {AggregatorV3Interface} from "@chainlink/contracts/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {console2} from "forge-std/Test.sol";

contract TokenSwap {
    address ETHUSDAddress = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
    address LINKUSDAddress = 0xc59E3633BAAC79493d908e63626716e204A45EdF;
    address DIAUSD = 0x14866185B1962B63C3Ea9E03Bc1da838bab34C19;
    AggregatorV3Interface internal dataFeed;

    // contract address
    address DAI = 0x3e622317f8C93f7328350cF0B56d9eD4C620C5d6;
    address LINK = 0x779877A7B0D9E8603169DdbD7836e478b4624789;

    mapping(address => uint256) public LinkDeposit;

    uint256 public DIADeposit;

    int public pairResult;

    int public testingGetDerivedPrice;

    event TokenSwapForETH(address from, address to, uint256 value);

    function getChainlinkDataFeedLatestAnswer(
        address _pairAddress
    ) public returns (int) {
        dataFeed = AggregatorV3Interface(_pairAddress);

        // prettier-ignore
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        pairResult = answer;
        return answer;
    }

    function AddLiquidity(
        uint256 _amountDia /*, uint256 _amountLink*/
    ) external {
        require(
            IERC20(DAI).transferFrom(msg.sender, address(this), _amountDia),
            "Deposit Faild for TokenA"
        );
        // require(
        //     IERC20(LINK).transferFrom(msg.sender, address(this), _amountLink),
        //     "Deposit Failed for TokenB"
        // );
        // LinkDeposit[msg.sender] = _amountLink;
        DIADeposit = DIADeposit + _amountDia;
    }

    // function ViewApproval() external view returns (uint256) {
    //     return IERC20(TokenA).allowance(msg.sender, address(this));
    // }

    // function SwapToken(uint256 _toAmount) external {
    //     require(swap(_toAmount), "Unable to Swap Token");
    // }

    // function swap(uint256 _value) internal returns (bool) {
    //     require(msg.sender != address(0x0), "Wrong EOA");

    //     ATokenDeposit[msg.sender] = ATokenDeposit[msg.sender] - _value;

    //     BTokenDeposit[msg.sender] = BTokenDeposit[msg.sender] + _value;
    //     //(success, _to.call{value:_value}(""));
    //     //_to.transfer(_value);
    //     // Event
    //     return true;
    // }

    function swapTokenForETH(address _base, uint256 _amount) external {
        int256 result = getDerivedPrice(_base, ETHUSDAddress, 8);

        DIADeposit = DIADeposit - uint256(result);
        uint256 amountOut = uint256(result) * _amount;

        console2.log(result);
        // payable(msg.sender).transfer(amountOut);

        emit TokenSwapForETH(address(this), msg.sender, amountOut);
    }

    function getDerivedPrice(
        address _base,
        address _quote,
        uint8 _decimals
    ) public view returns (int256) {
        require(
            _decimals > uint8(0) && _decimals <= uint8(18),
            "Invalid _decimals"
        );
        int256 decimals = int256(10 ** uint256(_decimals));
        (, int256 basePrice, , , ) = AggregatorV3Interface(_base)
            .latestRoundData();
        console2.log("Testing for Base Price", basePrice);
        uint8 baseDecimals = AggregatorV3Interface(_base).decimals();
        basePrice = scalePrice(basePrice, baseDecimals, _decimals);

        (, int256 quotePrice, , , ) = AggregatorV3Interface(_quote)
            .latestRoundData();
        uint8 quoteDecimals = AggregatorV3Interface(_quote).decimals();
        quotePrice = scalePrice(quotePrice, quoteDecimals, _decimals);

        return (basePrice * decimals) / quotePrice;
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

    fallback() external payable {}

    receive() external payable {}
}
