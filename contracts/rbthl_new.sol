// SPDX-License-Identifier:None

pragma solidity ^0.8.0;
/* IMPORTS */

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

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
interface IUSDT {
    function balanceOf(address account) external view returns (uint256);
    function mint(address account, uint256 amount) external payable;
    function burn(uint256 amount) external payable;
}

// ReleasePrice - $0.01

contract RabbitHoleToken is ERC20, Ownable, ReentrancyGuard {
    
    using SafeMath for uint256;

    AggregatorV3Interface internal ethPriceFeed;

    uint256 public distributed;

    uint256 public salePriceUsd = 10_000_000_000_000_000; //$0.01 ( 1e18 = 1 token , 1e16 = 0.01 token value)

    mapping(address => uint256) public toRefund;

    // address of admin
    address public adminAddress;

    // contract balance
    uint256 public balance;

    uint256 public constant INITIAL_SUPPLY = 100_000_000 * 1e18;

    mapping (address => uint256) public _toClaim;

    address public pair;

    IUSDT public USDT;

    IUniswapV2Router02 public router;


    // eth deposit mapping
    mapping (address => uint256) public  _ethDeposit;
    

    /* EVENTS */
        event Bought(address account, uint256 amount);
        event Locked(address account, uint256 amount);
        event Released(address account, uint256 amount);

        event Buy(address indexed from, uint256 amount);
        event Destroyed(uint256 burnedFunds);
        event Transferred(address indexed to, uint256 amount);

        event withdrawnETHDeposit(address indexed to, uint256 amount);

        // event Transfer(address indexed from, address indexed to, uint256 value); // IERC20.sol: Transfer(address, address, uint256)
    // 
    
    /* CONSTRUCTOR */
        constructor(
            address _dexRouter, 
            address _usdt
        ) ERC20("Rabbit Hole Token", "RBTHL") {
            _mint(msg.sender, INITIAL_SUPPLY);
            USDT = IUSDT(_usdt);
            isAdmin[msg.sender] = true;
            router = IUniswapV2Router02(_dexRouter);
            pair = IUniswapV2Factory(router.factory()).createPair(address(USDT), address(this));
            ethPriceFeed = AggregatorV3Interface(
                0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
            );
        }
    //

    event Claimed(address account, uint256 amount);

    /* ONLY OWNER */

        function setAdmin(address _adminAddress) external onlyOwner{
            require(_adminAddress != address(0), "!nonZero");
            adminAddress = _adminAddress;
        }

    /* GETTERS */

        function salePriceEth() public view returns (uint256) {
            (, int256 ethPriceUsd, , , ) = ethPriceFeed.latestRoundData();
            uint256 rbthlpriceInEth = (salePriceUsd.mul(10**18)).div(uint256(ethPriceUsd).mul(10**10));

            return rbthlpriceInEth;
        }

        function computeTokensAmount(uint256 funds) public view returns (uint256, uint256) {
            uint256 salePrice = salePriceEth();
            uint256 tokensToBuy = (funds.div(salePrice)).mul(10**18); // 0.5 6.5 = 6

            uint256 exceedingEther;
            
            return (tokensToBuy, exceedingEther);
        }

    /* EXTERNAL OR PUBLIC */

        receive() external payable {
            // revert("Direct funds receiving not enabled, call 'buy' directly");
        }

        function buy() public payable nonReentrant {

            require(totalSupply() > 0, "everything was sold");

            // compute the amount of token to buy based on the current rate
            (uint256 tokensToBuy, uint256 exceedingEther) = computeTokensAmount(
                msg.value
            );
            _toClaim[msg.sender] = _toClaim[msg.sender].add(tokensToBuy);


            balance += msg.value;   // add the funds to the balance

            // refund eventually exceeding eth
            if (exceedingEther > 0) {
                uint256 _toRefund = toRefund[msg.sender] + exceedingEther;
                toRefund[msg.sender] = _toRefund;
            }



            distributed = distributed.add(tokensToBuy);

            // Mint new tokens for each submission

            // eth deposit of user is stored in _ethDeposit
            _ethDeposit[msg.sender] = _ethDeposit[msg.sender].add(msg.value);

            emit Buy(msg.sender, tokensToBuy);
        }    

        function refund() public nonReentrant {
            require(toRefund[msg.sender] > 0, "Nothing to refund");

            uint256 _refund = toRefund[msg.sender];
            toRefund[msg.sender] = 0;

            // avoid impossibility to refund funds in case transaction are executed from a contract
            // (like gnosis safe multisig), this is a workaround for the 2300 fixed gas problem
            (bool refundSuccess, ) = msg.sender.call{value: _refund}("");
            require(refundSuccess, "Unable to refund exceeding ether");
        }


        // users can claim rbthl tokens
        function claim() external {
            require(_ethDeposit[msg.sender] > 0, "No ETH deposit to claim");

            transfer(msg.sender, _toClaim[msg.sender]);
        }

    //
        // transfer eth to admin
        function transferEthToAdmin() public onlyOwner {
            require(adminAddress != address(0), "Admin not set");
            
            payable(adminAddress).transfer(balance);
            balance = 0;
        }

         using SafeMath for uint256;



    // mapping to is eligible for tokens
    mapping (address => bool) public isEligible;

    // mapping to make admin
    mapping (address => bool) public isAdmin;

    modifier onlyAdmin() {
            require(isAdmin[msg.sender] == true, "Ownable: caller is not the admin");
            _;
    }

    function mint(uint256 _amount) external onlyOwner {
        // require(!address(0).eq(_to), "ERC20: transfer to the zero address");
        _mint(msg.sender, _amount);
    }

    function deposit(address _account, uint256 _amount) external onlyOwner {
        _mint(_account, _amount);
    }

    function auctionMint(address _account, uint256 _amount) external {
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
    function giveTokens(address _account, uint256 _amount) external {
        require(isAdmin[_account] == true, "No Admin Found");
        _mint(_account, _amount);
    }
}