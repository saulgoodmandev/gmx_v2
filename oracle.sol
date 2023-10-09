// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


    interface AggregatorV3Interface {
        function decimals() external view returns (uint8);

        function description() external view returns (string memory);

        function version() external view returns (uint256);

        function getRoundData(uint80 _roundId)
            external
            view
            returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
            );

        function latestRoundData()
            external
            view
            returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
            );
    }


    struct MarketProps {
        address marketToken;
        address indexToken;
        address longToken;
        address shortToken;
    }

    struct Price {
    int256 max;
    int256 min;
    }

    struct MarketPrices {
    Price indexTokenPrice;
    Price longTokenPrice;
    Price shortTokenPrice;
    }
    interface IReaderContract {
        function getWithdrawalAmountOut(
            address dataStore,
            MarketProps memory market,
            MarketPrices memory prices,
            uint256 marketTokenAmount,
            address uiFeeReceiver
        ) external view returns (uint256, uint256);
    }





    contract DataRetrievalContract {

        constructor() {
        
        }

        function getAnswerFromPriceContract(address oracle) public view returns (int256) {
            AggregatorV3Interface priceContract = AggregatorV3Interface(oracle);
            (
                uint80 roundId,
                int256 answer,
                uint256 startedAt,
                uint256 updatedAt,
                uint80 answeredInRound
            ) = priceContract.latestRoundData();

            return answer;
        }

        // Function to retrieve the amount using the reader contract
        function retrieveETHUSDCAmount(int256 price) external view returns (uint256, uint256) {
            // Create an instance of the reader contract
            IReaderContract readerContract = IReaderContract(0xf60becbba223EEA9495Da3f606753867eC10d139);

            // Define the parameters
            address dataStore = 0xFD70de6b91282D8017aA4E741e9Ae325CAb992d8;
            MarketProps memory market = MarketProps({
                marketToken: 0x70d95587d40A2caf56bd97485aB3Eec10Bee6336,
                indexToken: 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1,
                longToken: 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1,
                shortToken: 0xaf88d065e77c8cC2239327C5EDb3A432268e5831
            });

           MarketPrices memory prices = MarketPrices({
                indexTokenPrice: Price({
                    max: price,
                    min: price
                }),
                longTokenPrice: Price({
                    max: price,
                    min: price
                }),
                shortTokenPrice: Price({
                    max: 100000000,
                    min: 100000000
                })
            });


            uint256 marketTokenAmount = 1000000000000000000000;
            address uiFeeReceiver = 0x0000000000000000000000000000000000000000;

            // Call the reader contract's function
            (uint256 result1, uint256 result2) = readerContract.getWithdrawalAmountOut(
                dataStore,
                market,
                prices,
                marketTokenAmount,
                uiFeeReceiver
            );

            return (result1,result2);

        }
        // Function to retrieve the amount using the reader contract
        function retrieveETHUSDCAmount(MarketProps memory market, MarketPrices memory prices) external view returns (uint256, uint256) {
            // Create an instance of the reader contract
            IReaderContract readerContract = IReaderContract(0xf60becbba223EEA9495Da3f606753867eC10d139);

            // Define the parameters
            address dataStore = 0xFD70de6b91282D8017aA4E741e9Ae325CAb992d8;
           
            uint256 marketTokenAmount = 1000000000000000000000000;
            address uiFeeReceiver = 0x0000000000000000000000000000000000000000;

            // Call the reader contract's function
            (uint256 result1, uint256 result2) = readerContract.getWithdrawalAmountOut(
                dataStore,
                market,
                prices,
                marketTokenAmount,
                uiFeeReceiver
            );

            return (result1,result2);

        }
    }
