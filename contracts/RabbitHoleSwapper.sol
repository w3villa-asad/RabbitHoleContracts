// contracts/RabbitHoleSwapper.sol
// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

contract RabbitHoleSwapper is Ownable {

    ISwapRouter public immutable swapRouter;
    address public token;
    address public adminAddress;

    address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint24 public constant poolFee = 3000;

    uint256 MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    
    constructor(
        ISwapRouter _router, 
        address _token, 
        address _adminAddress
    ) {
        swapRouter = _router;
        token = _token;
        adminAddress = _adminAddress;
    }

    receive() external payable {}

    function performSwap(uint256 _amount) external {
        require(_amount > 0, 'Swapper: amount must be greater than 0');
        // Transfer the specified amount of RBTHL to this contract.
        TransferHelper.safeTransferFrom(token, msg.sender, address(this), _amount);

        // Approve the router to spend RBTHL.
        TransferHelper.safeApprove(token, address(swapRouter), _amount);

        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: token,
                tokenOut: WETH9,
                fee: poolFee,
                deadline: block.timestamp,
                recipient: address(this),
                amountIn: _amount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        uint256 amountOut = swapRouter.exactInputSingle(params);

        IWETH9(WETH9).withdraw(amountOut);
        TransferHelper.safeTransferETH(adminAddress, amountOut);
    }

}