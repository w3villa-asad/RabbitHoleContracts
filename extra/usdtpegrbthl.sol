
//SPDX-License-Identifier: None

pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";

// chainlink aggregator contract
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}


contract RabbitHoleToken is ERC20, Ownable {

    using SafeMath for uint256;

    uint256 public constant INITIAL_SUPPLY = 100_000_000 * 1e18;

    // uint256 public cost;

    uint256 public salePriceUsd = 1_000_000; // 1 USD

    address public pair;

    address public USDT = 0xc9eead045d07179C8d360132de882006398CCc73;

    IUniswapV2Router02 public router;

    // mapping to is eligible for tokens
    mapping (address => bool) public isEligible;

    // mapping to make admin
    mapping (address => bool) public isAdmin;

    modifier onlyAdmin() {
            require(isAdmin[msg.sender] == true, "Ownable: caller is not the admin");
            _;
    }


    AggregatorV3Interface internal priceFeed;

    constructor(address _dexRouter) ERC20("Rabbit Hole Token", "RBTHL") {
        _mint(msg.sender, INITIAL_SUPPLY);
        isAdmin[msg.sender] = true;
        router = IUniswapV2Router02(_dexRouter);
        pair = IUniswapV2Factory(router.factory()).createPair(address(USDT), address(this));
        priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
    }

    function mint(uint256 _amount) external onlyOwner {
        // require(!address(0).eq(_to), "ERC20: transfer to the zero address");
        _mint(msg.sender, _amount);
    }

    function deposit(address _account, uint256 _amount) external onlyOwner {
        _mint(_account, _amount);
    }

    // to add admins
    function addAdmin(address _account) external onlyOwner {
        require(isAdmin[_account] == false, "You Are Already An Admin");
        isAdmin[_account] = true;
    }

    // to remove admins
    function removeAdmin(address account)public onlyOwner {
        require(isAdmin[account] == true, "No Admin Found");
            isAdmin[account] = false;
        }

    // function for admin to transfer tokens to user
    function giveTokens(address _account, uint256 _amount) external onlyAdmin {
        _mint(_account, _amount);
    }

    function salePriceETH() public view returns (uint256) {
            (, int256 ethPriceUsd, , , ) = priceFeed.latestRoundData();
            uint256 rabbitholepriceInETH = (salePriceUsd.mul(10**18)).div(uint256(ethPriceUsd).mul(10**10));

            return rabbitholepriceInETH;
    }

    // get current price 
    function getCurrentPrice() public view returns (uint256) {
        (uint112 balance1, uint112 balance0, ) = IUniswapV2Pair(pair).getReserves();
        if (balance1 == 0) {
            return 0;
        }
        uint256 ratio = uint256(balance0).div(balance1); // token price in WAVAX
        uint256 priceInDollars = ratio.mul(getPrice());
        return priceInDollars;
    }

    function getPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    // function buy() public payable {
    //     // uint256 price = getCurrentPrice();
    //     // uint256 amount = msg.value;
    //     // uint256 amountInWAVAX = amount.mul(price);
    //     // _mint(msg.sender, amountInWAVAX);
    // }

     IERC20 usdt = IERC20(USDT_ADDRESS);

    // Token to send for USDT
    IERC20 token = address(this);

    function deposit(uint256 amount) public {
        // Transfer amount USDT tokens from msg.sender to contract
        usdt.transferFrom(msg.sender, address(this), amount);

        // Send amount tokens to msg.sender
        token.transfer(msg.sender, amount);
    }

    // buyback and burn the tokens
    function buyback(uint256 amount) public {
        // Transfer amount tokens from contract to msg.sender
        token.transfer(msg.sender, amount);

        // Burn amount tokens from contract
        token.transferFrom(address(this), address(0), amount);
    }

}