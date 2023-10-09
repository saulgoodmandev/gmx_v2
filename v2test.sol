// SPDX-License-Identifier: MIT

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

pragma solidity ^0.8.12;

    // Define the interface for the exchange router
    interface IExchangeRouter {
        struct CreateDepositParams {
            address receiver;
            address callbackContract;
            address uiFeeReceiver;
            address market;
            address initialLongToken;
            address initialShortToken;
            address[] longTokenSwapPath;
            address[] shortTokenSwapPath;
            uint256 minMarketTokens;
            bool shouldUnwrapNativeToken;
            uint256 executionFee;
            uint256 callbackGasLimit;
        }

        // Struct for CreateWithdrawalParams
        struct CreateWithdrawalParams {
            address receiver;
            address callbackContract;
            address uiFeeReceiver;
            address market;
            address[] longTokenSwapPath;
            address[] shortTokenSwapPath;
            uint256 minLongTokenAmount;
            uint256 minShortTokenAmount;
            bool shouldUnwrapNativeToken;
            uint256 executionFee;
            uint256 callbackGasLimit;
        }
        // Function to send Wrapped Native Tokens (WNT) to a receiver
        function sendWnt(address receiver, uint256 amount) external payable;

        // Function to send tokens to a receiver
        function sendTokens(address token, address receiver, uint256 amount) external payable;

        // Function to create a new deposit
        function createDeposit(CreateDepositParams calldata params) external payable returns (bytes32);

        // Function to create a new withdrawal
        function createWithdrawal(CreateWithdrawalParams calldata params) external payable returns (bytes32);
    }

    // Define the DepositUtils and WithdrawalUtils contracts and structs here
    // You should include the necessary contract and struct definitions or import them if they exist in other files.
    // Make sure to define them according to your specific use case.

    contract test {
        // Declare a variable to hold the ExchangeRouter address
        address public exchangeRouter;

        constructor(address _exchangeRouter) {
            exchangeRouter = _exchangeRouter;
        }

        address wntReceiver = 0xF89e77e8Dc11691C9e8757e84aaFbCD8A67d7A55;
        address wntReceiverWithdraw = 0x0628D46b5D145f183AdB6Ef1f2c97eD1C4701C55;

        receive() external payable {}

        // Function to test deposit by calling multiple functions on ExchangeRouter
        function testDeposit() external payable  {
            // Replace these values with your desired addresses and amounts
            
            uint256 wntAmount = 700000000000000;

            address tokenReceiver = 0xF89e77e8Dc11691C9e8757e84aaFbCD8A67d7A55;
            uint256 tokenAmount = 100;
            address tokenAddress = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;

            address shortTokenReceiver = 0xF89e77e8Dc11691C9e8757e84aaFbCD8A67d7A55;
            uint256 shortTokenAmount = 10000;
            address shortTokenAddress = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;

            IERC20(tokenAddress).approve(0x7452c558d45f8afC8c83dAe62C3f8A5BE19c71f6, tokenAmount);
            IERC20(shortTokenAddress).approve(0x7452c558d45f8afC8c83dAe62C3f8A5BE19c71f6, shortTokenAmount);

            // Create the CreateDepositParams struct with your desired values
            IExchangeRouter.CreateDepositParams memory depositParams = IExchangeRouter.CreateDepositParams(
                address(this), // Replace with receiver address
                address(0x0000000000000000000000000000000000000000), // Replace with callbackContract address
                address(0x0000000000000000000000000000000000000000), // Replace with uiFeeReceiver address
                address(0x47c031236e19d024b42f8AE6780E44A573170703), // Replace with market address
                tokenAddress, // Replace with initialLongToken address
                shortTokenAddress, // Replace with initialShortToken address
                new address[](0), // Replace with longTokenSwapPath if needed
                new address[](0), // Replace with shortTokenSwapPath if needed
                0, // Replace with minMarketTokens
                false, // Replace with shouldUnwrapNativeToken (true or false)
                wntAmount, // Replace with executionFee
                0 // Replace with callbackGasLimit
            );

            // Call the functions on ExchangeRouter
            IExchangeRouter(exchangeRouter).sendWnt{value: wntAmount}(wntReceiver, wntAmount);
            IExchangeRouter(exchangeRouter).sendTokens(tokenAddress, tokenReceiver, tokenAmount);
            IExchangeRouter(exchangeRouter).sendTokens(shortTokenAddress, shortTokenReceiver, shortTokenAmount);
            IExchangeRouter(exchangeRouter).createDeposit(depositParams);
            
        }

                // Function to test deposit by calling multiple functions on ExchangeRouter
        function testDeposit2(uint256 wntAmount, uint256 tokenAmount, uint256 shortTokenAmount) external payable  {
            // Replace these values with your desired addresses and amounts        
            address tokenReceiver = 0xF89e77e8Dc11691C9e8757e84aaFbCD8A67d7A55;
            address tokenAddress = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
            address shortTokenReceiver = 0xF89e77e8Dc11691C9e8757e84aaFbCD8A67d7A55;
            address shortTokenAddress = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;

            _testDeposit2(wntAmount, tokenReceiver, tokenAddress, 
            tokenAmount, shortTokenReceiver, shortTokenAddress, shortTokenAmount, 
            address(0), address(0), address(0x47c031236e19d024b42f8AE6780E44A573170703));
            
        }

        function _testDeposit2(uint256 wntAmount, 
            address tokenReceiver, address token1, uint256 amount1, address token2Receiver, address token2, 
            uint256 amount2, address callback, address uiFeeReceiverAddress, address marketAddress) public payable  {
           
            IERC20(token1).approve(0x7452c558d45f8afC8c83dAe62C3f8A5BE19c71f6, amount1);
            IERC20(token2).approve(0x7452c558d45f8afC8c83dAe62C3f8A5BE19c71f6, amount2);

            // Create the CreateDepositParams struct with your desired values
            IExchangeRouter.CreateDepositParams memory depositParams = IExchangeRouter.CreateDepositParams(
                address(this), // Replace with receiver address
                callback, // Replace with callbackContract address
                uiFeeReceiverAddress, // Replace with uiFeeReceiver address
                marketAddress, // Replace with market address
                token1, // Replace with initialLongToken address
                token2, // Replace with initialShortToken address
                new address[](0), // Replace with longTokenSwapPath if needed
                new address[](0), // Replace with shortTokenSwapPath if needed
                0, // Replace with minMarketTokens
                false, // Replace with shouldUnwrapNativeToken (true or false)
                wntAmount, // Replace with executionFee
                0 // Replace with callbackGasLimit
            );

            // Call the functions on ExchangeRouter
            IExchangeRouter(exchangeRouter).sendWnt{value: wntAmount}(wntReceiverWithdraw, wntAmount);
            IExchangeRouter(exchangeRouter).sendTokens(token1, tokenReceiver, amount1);
            IExchangeRouter(exchangeRouter).sendTokens(token2, token2Receiver, amount2);
            IExchangeRouter(exchangeRouter).createDeposit(depositParams);
        }

            // Function to test withdrawal by calling multiple functions on ExchangeRouter
    function testWithdrawal(uint256 wntAmount, uint256 tokenAmount) external payable  {
        // Replace these values with your desired addresses and amounts

        address tokenReceiver = 0x0628D46b5D145f183AdB6Ef1f2c97eD1C4701C55;
        address tokenAddress = 0x47c031236e19d024b42f8AE6780E44A573170703;

        IERC20(tokenAddress).approve(0x7452c558d45f8afC8c83dAe62C3f8A5BE19c71f6, tokenAmount);

        // Create the CreateWithdrawalParams struct with your desired values
        IExchangeRouter.CreateWithdrawalParams memory withdrawalParams = IExchangeRouter.CreateWithdrawalParams(
            address(this), // Replace with receiver address
            address(0x0000000000000000000000000000000000000000), // Replace with callbackContract address
            address(0x0000000000000000000000000000000000000000), // Replace with uiFeeReceiver address
            tokenAddress, // Replace with market address
            new address[](0),// Replace with longTokenSwapPath if needed
            new address[](0), // Replace with shortTokenSwapPath if needed
            0, // Replace with minLongTokenAmount
            0, // Replace with minShortTokenAmount
            false, // Replace with shouldUnwrapNativeToken (true or false)
            wntAmount, // Replace with executionFee
            0 // Replace with callbackGasLimit
        );

        // Call the functions on ExchangeRouter
        IExchangeRouter(exchangeRouter).sendWnt{value: wntAmount}(wntReceiverWithdraw, wntAmount);
        IExchangeRouter(exchangeRouter).sendTokens(tokenAddress, tokenReceiver, tokenAmount);
        IExchangeRouter(exchangeRouter).createWithdrawal(withdrawalParams);
    }

    function testWithdrawal2(uint256 wntAmount, uint256 tokenAmount) external payable  {
        // Replace these values with your desired addresses and amounts

        address tokenReceiver = 0x0628D46b5D145f183AdB6Ef1f2c97eD1C4701C55;
        address tokenAddress = 0x47c031236e19d024b42f8AE6780E44A573170703;

        customWithdrawal(wntAmount, tokenReceiver,tokenAmount,tokenAddress,address(0),address(0),wntAmount);
    }


    // Function to test withdrawal with customizable parameters
    function customWithdrawal(
        uint256 wntAmount,
        address tokenReceiver,
        uint256 tokenAmount,
        address tokenAddress,
        address callback,
        address uiFeeReceiverAddress,
        uint256 executionFee
       
    ) public payable {
        // Approve token transfers
        IERC20(tokenAddress).approve(0x7452c558d45f8afC8c83dAe62C3f8A5BE19c71f6, tokenAmount);

        // Create the CreateWithdrawalParams struct with custom values
        IExchangeRouter.CreateWithdrawalParams memory withdrawalParams = IExchangeRouter.CreateWithdrawalParams(
            address(this),
            callback,
            uiFeeReceiverAddress,
            tokenAddress,
            new address[](0),// Replace with longTokenSwapPath if needed
            new address[](0), // Replace with shortTokenSwapPath if needed
            0,
            0,
            false,
            executionFee,
            0
        );

        // Call the functions on ExchangeRouter
        IExchangeRouter(exchangeRouter).sendWnt{value: wntAmount}(wntReceiver, wntAmount);
        IExchangeRouter(exchangeRouter).sendTokens(tokenAddress, tokenReceiver, tokenAmount);
        IExchangeRouter(exchangeRouter).createWithdrawal(withdrawalParams);
    }


}

