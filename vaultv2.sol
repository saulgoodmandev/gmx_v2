
// SPDX-License-Identifier: MIT

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

pragma solidity ^0.8.20;

    interface GDtoken is IERC20{
        function mint(address recipient, uint256 _amount) external;
        function burn(address _from, uint256 _amount) external ;
    }

    interface IERC20Extented is IERC20 {
    function decimals() external  view returns (uint8);
    }

    interface oracle {
        function getGMETHprice() external  view returns(uint256);
        function getGMBTCprice() external  view returns(uint256);
        function getAssetPrice() external view returns(uint256);
        function getStableAssetPrice() external pure returns(uint256);
    }

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

    

    struct PoolInfo {
        IERC20 lpToken;    
        GDtoken GDlptoken; 
        uint256 EarnRateSec;     
        uint256 totalStaked; 
        uint256 lastUpdate; 
        uint256 vaultcap;
        uint256 depositFees;
        uint256 withdrawFees;
        uint256 APR;
        bool stakable;
        bool withdrawable;
        bool rewardStart;
    }

  

    // Define the DepositUtils and WithdrawalUtils contracts and structs here
    // You should include the necessary contract and struct definitions or import them if they exist in other files.
    // Make sure to define them according to your specific use case.

    contract vaultv2 is ReentrancyGuard, Ownable{

        using SafeERC20 for IERC20;
        using SafeMath for uint256;

        address public rebalanceRole;
        oracle public Oracle;

        // Declare a variable to hold the ExchangeRouter address
        address public exchangeRouter;
        PoolInfo[] public poolInfo;

        IERC20 public WETH = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
        IERC20 public USDC = IERC20(0xaf88d065e77c8cC2239327C5EDb3A432268e5831);
        address GMarketAddress = 0x70d95587d40A2caf56bd97485aB3Eec10Bee6336;

        struct UserWithdrawAmount {
            uint256 ethAmount;
            uint256 usdcAmount;
            uint256 burnEthGDAmount;
            uint256 burnUsdcGDAmount;
        }

        struct TotalPendingWithdrawAmount {
            uint256 ethAmount;
            uint256 usdcAmount;
        }

        TotalPendingWithdrawAmount public totalPendingWithdraw;
        TotalPendingWithdrawAmount public totalPendingWithdrawAfterContractAmount;


        mapping(address => UserWithdrawAmount) public withdrawMap;
        constructor(address _oracle, address _exchangeRouter, GDtoken _gdUSDC, GDtoken _gdETH) Ownable(msg.sender) {
            exchangeRouter = _exchangeRouter;
            rebalanceRole = msg.sender;
            Oracle = oracle(_oracle);

            poolInfo.push(PoolInfo({
                lpToken: USDC,
                GDlptoken: _gdUSDC,
                totalStaked:0,
                EarnRateSec:0,
                lastUpdate: block.timestamp,
                vaultcap: 0,
                stakable: true,
                withdrawable: true,
                rewardStart: false,
                depositFees: 250, 
                withdrawFees: 250, 
                APR: 1000
                
            }));

            poolInfo.push(PoolInfo({
                lpToken: WETH,
                GDlptoken: _gdETH,
                totalStaked:0,
                EarnRateSec:0,
                lastUpdate: block.timestamp,
                vaultcap: 0,
                stakable: true,
                withdrawable: true,
                rewardStart: false,
                depositFees: 250,
                withdrawFees: 250, 
                APR: 800
                
            }));

            
          
        }

        address wntReceiver = 0xF89e77e8Dc11691C9e8757e84aaFbCD8A67d7A55;
        address wntReceiverWithdraw = 0x0628D46b5D145f183AdB6Ef1f2c97eD1C4701C55;

        receive() external payable {}

        function updateOracle(oracle _oracle) external onlyOwner{
            Oracle = _oracle;
        }

        function updateRebalancer(address _rebalance) external onlyOwner{
            rebalanceRole = _rebalance;
        }

        function Router(address _router) external onlyOwner{
            exchangeRouter = _router;
        }

        function getWithdrawETHneeded() external view returns(uint256){
            if (totalPendingWithdraw.ethAmount >= WETH.balanceOf(address(this))){
                return totalPendingWithdraw.ethAmount.sub(WETH.balanceOf(address(this)));

            }
            else {
                return 0;
            }

        }

        function getWithdrawUSDCneeded() external view returns(uint256){
            if (totalPendingWithdraw.usdcAmount >= USDC.balanceOf(address(this))){
                return totalPendingWithdraw.usdcAmount.sub(USDC.balanceOf(address(this)));

            }
            else {
                return 0;
            }

        }
        function getFreeWETH() external view returns(uint256){
              if (totalPendingWithdraw.ethAmount >= WETH.balanceOf(address(this))){
                return 0;
            }
            else {
                
                return WETH.balanceOf(address(this)).sub(totalPendingWithdraw.ethAmount);

            }

        }
        function getFreeUSDC() external view returns(uint256){
            if (totalPendingWithdraw.usdcAmount >= USDC.balanceOf(address(this))){
                return 0;
            }
            else {
                
                return USDC.balanceOf(address(this)).sub(totalPendingWithdraw.usdcAmount);

            }

        }

        function setFees(uint256 _pid, uint256 _percent) external onlyOwner {
            require(_percent < 1000, "not in range");
            poolInfo[_pid].depositFees = _percent;
        }

        function setWithdrawFees(uint256 _pid, uint256 _percent) external onlyOwner {
            require(_percent < 1000, "not in range");
            poolInfo[_pid].withdrawFees = _percent;
        }

        // Unlocks the staked + gained USDC and burns xUSDC
        function updatePool(uint256 _pid) internal {
            uint256 timepass = block.timestamp.sub(poolInfo[_pid].lastUpdate);
            poolInfo[_pid].lastUpdate = block.timestamp;
            uint256 reward = poolInfo[_pid].EarnRateSec.mul(timepass);
            poolInfo[_pid].totalStaked = poolInfo[_pid].totalStaked.add(reward);
            
        }

        function currentPoolTotal(uint256 _pid) public view returns (uint256) {
            uint reward =0;
            if (poolInfo[_pid].rewardStart) {
                uint256 timepass = block.timestamp.sub(poolInfo[_pid].lastUpdate);
                reward = poolInfo[_pid].EarnRateSec.mul(timepass);
            }
            return poolInfo[_pid].totalStaked.add(reward);
        }

        function displayStakedBalance(address _address, uint256 _pid) public view returns(uint256) {
            GDtoken GDT = poolInfo[_pid].GDlptoken;
            uint256 totalShares = GDT.totalSupply();
            uint256 amountOut = GDT.balanceOf(_address).mul(currentPoolTotal(_pid)).div(totalShares);
            return amountOut;
        }

        function updatePoolRate(uint256 _pid) internal {
            poolInfo[_pid].EarnRateSec =  poolInfo[_pid].totalStaked.mul(poolInfo[_pid].APR).div(10**4).div(365 days);
        }


        function setPoolCap(uint256 _pid, uint256 _vaultcap) external onlyOwner {
            poolInfo[_pid].vaultcap = _vaultcap;
        }

        function setAPR(uint256 _pid, uint256 _apr) external onlyOwner {
            require(_apr > 200 && _apr < 4000, " apr not in range");
            poolInfo[_pid].APR = _apr;
            if (poolInfo[_pid].rewardStart){
                updatePool(_pid);
            }
            updatePoolRate(_pid);
        }

        function setOpenVault(uint256 _pid, bool open) external onlyOwner {

            poolInfo[_pid].stakable = open;
            
        }

        function setOpenAllVault(bool open) external onlyOwner {
            for (uint256 _pid = 0; _pid < poolInfo.length; ++ _pid){
                poolInfo[_pid].stakable = open;
            }
            
        }

        function startReward(uint256 _pid) external onlyOwner {
            require(!poolInfo[_pid].rewardStart, "already started");
            poolInfo[_pid].rewardStart = true;
            poolInfo[_pid].lastUpdate = block.timestamp;
            
        }

        function pauseReward(uint256 _pid) external onlyOwner {
            require(poolInfo[_pid].rewardStart, "not started");

            updatePool(_pid);
            updatePoolRate(_pid);
            poolInfo[_pid].rewardStart = false;
            poolInfo[_pid].lastUpdate = block.timestamp;
            
        }

        function openWithdraw(uint256 _pid, bool open) external onlyOwner {

            poolInfo[_pid].withdrawable = open;
        }

        function openAllWithdraw(bool open) external onlyOwner {

            for (uint256 _pid = 0; _pid < poolInfo.length; ++ _pid){

                poolInfo[_pid].withdrawable = open;
            }
        }

        function checkDuplicate(GDtoken _GDlptoken) internal view returns(bool) {
        
            for (uint256 i = 0; i < poolInfo.length; ++i){
                if (poolInfo[i].GDlptoken == _GDlptoken){
                    return false;
                }        
            }
            return true;
        }

        function GDpriceToStakedtoken(uint256 _pid) public view returns(uint256) {
            GDtoken GDT = poolInfo[_pid].GDlptoken;
            uint256 totalShares = GDT.totalSupply();
            // Calculates the amount of USDC the xUSDC is worth
            uint256 amountOut = (currentPoolTotal(_pid)).mul(10**18).div(totalShares);
            return amountOut;
        }

        function enter(uint256 _amountin, uint256 _pid) public nonReentrant {

            require(_amountin > 0, "invalid amount");
            uint256 _amount = _amountin;
        
            GDtoken GDT = poolInfo[_pid].GDlptoken;
            IERC20 StakedToken = poolInfo[_pid].lpToken;

            uint256 decimalMul = 18 - IERC20Extented(address(StakedToken)).decimals();
            
            //decimals handlin
            _amount = _amountin.mul(10**decimalMul);
            

            require(_amountin <= StakedToken.balanceOf(msg.sender), "balance too low" );
            require(poolInfo[_pid].stakable, "not stakable");
            require((poolInfo[_pid].totalStaked + _amount) <= poolInfo[_pid].vaultcap, "cant deposit more than vault cap");

            if (poolInfo[_pid].rewardStart){
                updatePool(_pid);
            }
            
            // Gets the amount of USDC locked in the contract
            uint256 totalStakedTokens = poolInfo[_pid].totalStaked;
            // Gets the amount of gdUSDC in existence
            uint256 totalShares = GDT.totalSupply();

            uint256 balanceMultipier = 100000 - poolInfo[_pid].depositFees;
            uint256 amountAfterFee = _amount.mul(balanceMultipier).div(100000);
            // If no gdUSDC exists, mint it 1:1 to the amount put in
            if (totalShares == 0 || totalStakedTokens == 0) {
                GDT.mint(msg.sender, amountAfterFee);
            } 
            // Calculate and mint the amount of gdUSDC the USDC is worth. The ratio will change overtime
            else {
                uint256 what = amountAfterFee.mul(totalShares).div(totalStakedTokens);
                GDT.mint(msg.sender, what);
            }
            
            poolInfo[_pid].totalStaked = poolInfo[_pid].totalStaked.add(amountAfterFee);

            updatePoolRate(_pid);
            StakedToken.safeTransferFrom(msg.sender, address(this), _amountin);       
        }

        function leave(uint256 _share, uint256 _pid) public  nonReentrant returns(uint256){

            GDtoken GDT = poolInfo[_pid].GDlptoken;
            IERC20 StakedToken = poolInfo[_pid].lpToken;

            require(_share <= GDT.balanceOf(msg.sender), "balance too low");
            require(poolInfo[_pid].withdrawable, "withdraw window not opened");

            if (poolInfo[_pid].rewardStart){
                updatePool(_pid);
            }


            // Gets the amount of xUSDC in existence
            uint256 totalShares = GDT.totalSupply();
            // Calculates the amount of USDC the xUSDC is worth
            uint256 amountOut = _share.mul(poolInfo[_pid].totalStaked).div(totalShares);

            poolInfo[_pid].totalStaked = poolInfo[_pid].totalStaked.sub(amountOut);
            updatePoolRate(_pid);

            uint256 amountSendOut = amountOut;

            uint256 decimalMul = 18 - IERC20Extented(address(StakedToken)).decimals();
            
            //decimals handlin
            amountSendOut = amountOut.div(10**decimalMul);   
            uint256 balanceMultipier = 100000 - poolInfo[_pid].withdrawFees;
            amountSendOut = amountSendOut.mul(balanceMultipier).div(100000);

            GDT.burn(msg.sender, _share);

            if (_pid == 1){
                withdrawMap[msg.sender].ethAmount = withdrawMap[msg.sender].ethAmount.add(amountSendOut);
       
                totalPendingWithdraw.ethAmount = totalPendingWithdraw.ethAmount.add(amountSendOut); 


            }
            else {
                withdrawMap[msg.sender].usdcAmount = withdrawMap[msg.sender].usdcAmount.add(amountSendOut);
                totalPendingWithdraw.usdcAmount = totalPendingWithdraw.usdcAmount.add(amountSendOut); 
            }
            
        
            return amountSendOut;
        }

        function resetUserWithdraw(address account) internal {
            withdrawMap[account].ethAmount = 0;
            withdrawMap[account].usdcAmount = 0;
            withdrawMap[account].burnEthGDAmount = 0;
            withdrawMap[account].burnUsdcGDAmount = 0;
        }

        function withdraw() public  nonReentrant { 
           uint256 ethAmountSendOut = withdrawMap[msg.sender].ethAmount;
           uint256 usdcAmountSendOut = withdrawMap[msg.sender].usdcAmount;
           
 

           resetUserWithdraw(msg.sender);
           totalPendingWithdraw.ethAmount = totalPendingWithdraw.ethAmount.sub(ethAmountSendOut);
           totalPendingWithdraw.usdcAmount = totalPendingWithdraw.usdcAmount.sub(usdcAmountSendOut);

           WETH.safeTransfer(msg.sender, ethAmountSendOut);
           USDC.safeTransfer(msg.sender, usdcAmountSendOut);

        }

        function withdrawable(address account) public view returns(bool)  { 
           uint256 ethAmountSendOut = withdrawMap[account].ethAmount;
           uint256 usdcAmountSendOut = withdrawMap[account].usdcAmount;
           return (WETH.balanceOf(address(this)) >= ethAmountSendOut && USDC.balanceOf(address(this)) >=usdcAmountSendOut);

        }

        function totalUSDvault() public view returns(uint256) {
            uint256 tokenPrice = Oracle.getAssetPrice();
            uint256 StablePrice = Oracle.getStableAssetPrice();
            uint256 totalStakedTokens = currentPoolTotal(1);
            uint256 totalStableStakedTokens = currentPoolTotal(0);
            uint256 totalUSD = tokenPrice.mul(totalStakedTokens).div(10**18); //decials 8 
            uint256 totalUSD2 = StablePrice.mul(totalStableStakedTokens).div(10**18); //decials 8 
            return totalUSD.add(totalUSD2);
        }

        function totalGMUSD() public view returns(uint256) {            
            uint256 GMprice = Oracle.getGMETHprice();
            uint256 GMamount = IERC20(GMarketAddress).balanceOf(address(this));
            return GMamount.mul(GMprice).div(10**28); //decials 8 
        }

        function withdrawProfit(IERC20 token, uint256 _amount) external onlyOwner {
            require(totalGMUSD() > totalUSDvault(), "undervalue");
            require(token != IERC20(GMarketAddress), "cant withdraw backing");
            token.transfer(owner(), _amount);
        }

        function withdrawARB(uint256 _amount) external onlyOwner {
            IERC20 token = IERC20(0x912CE59144191C1204E64559FE8253a0e49E6548);
            token.transfer(owner(), _amount);
        }

        // Function to withdraw all Ether from this contract to the owner
        function withdrawETH() external onlyOwner {
            uint256 balance = address(this).balance;
            require(balance > 0, "Contract balance is zero");

            (bool sent, ) = payable(owner()).call{value: balance}("");
            require(sent, "Failed to send Ether");
        }
                // Function to test deposit by calling multiple functions on ExchangeRouter
        function BuyGMtokens(uint256 wntAmount, uint256 tokenAmount, uint256 shortTokenAmount) external payable  {

            require(msg.sender ==  rebalanceRole,"not rebalancer");
            // Replace these values with your desired addresses and amounts        
            address tokenReceiver = 0xF89e77e8Dc11691C9e8757e84aaFbCD8A67d7A55;
            address tokenAddress = address(WETH);
            address shortTokenReceiver = 0xF89e77e8Dc11691C9e8757e84aaFbCD8A67d7A55;
            address shortTokenAddress = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;

            _buyGMtokens(wntAmount, tokenReceiver, tokenAddress, 
            tokenAmount, shortTokenReceiver, shortTokenAddress, shortTokenAmount, 
            address(0), address(0), GMarketAddress);
            
        }

        function _buyGMtokens(uint256 wntAmount, 
            address tokenReceiver, address token1, uint256 amount1, address token2Receiver, address token2, 
            uint256 amount2, address callback, address uiFeeReceiverAddress, address marketAddress) internal  {

           
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
            IExchangeRouter(exchangeRouter).sendWnt{value: wntAmount}(wntReceiver, wntAmount);
            IExchangeRouter(exchangeRouter).sendTokens(token1, tokenReceiver, amount1);
            IExchangeRouter(exchangeRouter).sendTokens(token2, token2Receiver, amount2);
            IExchangeRouter(exchangeRouter).createDeposit(depositParams);
        }


        function SwapToAssets(uint256 wntAmount, uint256 tokenAmount) external payable  {

            require(msg.sender ==  rebalanceRole,"not rebalancer");
            // Replace these values with your desired addresses and amounts

            address tokenReceiver = 0x0628D46b5D145f183AdB6Ef1f2c97eD1C4701C55;
            address tokenAddress = GMarketAddress;

            _swapToAssets(wntAmount, tokenReceiver,tokenAmount,tokenAddress,address(0),address(0),wntAmount);
        }


        // Function to test withdrawal with customizable parameters
        function _swapToAssets(
            uint256 wntAmount,
            address tokenReceiver,
            uint256 tokenAmount,
            address tokenAddress,
            address callback,
            address uiFeeReceiverAddress,
            uint256 executionFee
        
        ) internal {
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
            IExchangeRouter(exchangeRouter).sendWnt{value: wntAmount}(wntReceiverWithdraw, wntAmount);
            IExchangeRouter(exchangeRouter).sendTokens(tokenAddress, tokenReceiver, tokenAmount);
            IExchangeRouter(exchangeRouter).createWithdrawal(withdrawalParams);
        }


}

