// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract StringToInt {
    function stringToInt(
        string memory str,
        uint8 precision
    ) public pure returns (uint256) {
        // Convert the string to an integer by removing the decimal point and parsing it
        bytes memory strBytes = bytes(str);
        uint256 intValue = 0;
        bool decimalOccured = false;
        uint256 afterDecimal = 0;

        for (uint i = 0; i < strBytes.length; i++) {
            uint8 charCode = uint8(strBytes[i]);
            if (charCode >= 48 && charCode <= 57) {
                intValue = intValue * 10 + (charCode - 48);
                if (decimalOccured) {
                    afterDecimal += 1;
                }
            } else if (charCode == 46) {
                decimalOccured = true;
            }
        }

        // Apply the desired precision
        while (afterDecimal > precision) {
            intValue /= 10;
            afterDecimal -= 1;
        }

        while (afterDecimal < precision) {
            intValue *= 10;
            afterDecimal += 1;
        }

        return intValue;
    }
}

contract InferCallContract {
    function inferCall(
        string memory modelName,
        string calldata inputData
    ) public view returns (bytes32) {
        bytes32[2] memory output;
        bytes memory args = abi.encodePacked(modelName, "-", inputData);
        assembly {
            if iszero(
                staticcall(
                    not(0),
                    0x100,
                    add(args, 32),
                    mload(args),
                    output,
                    12
                )
            ) {
                revert(0, 0)
            }
        }
        return output[0];
    }
}

/**
    This smart contract demo the ability to use ML/AI inference directly on-chain
 */

contract RiskEngine is InferCallContract, StringToInt {
    event RiskMetricUpdate(address _tokenAddress, uint256 _riskMetric);
    event ClassificationResultUpdate(
        address _tokenAddress,
        uint256 _classification
    );
    mapping(address => uint256) public riskMetricByAddress;
    mapping(address => uint256) public classificationResultByAddress;

    function setRiskMetricByToken(
        address tokenAddress,
        string calldata inputData
    ) public {
        string memory classificationModelHash = string(
            abi.encodePacked("QmYrQvh6ixW1oQUK5Lehjmqk5eSsthiUXwQVFQA7BDf9yv")
        );
        string memory classificationResult = string(
            abi.encodePacked(inferCall(classificationModelHash, inputData))
        );

        string memory modalHash;
        uint256 classification;
        if (
            keccak256(abi.encodePacked(classificationResult)) ==
            keccak256(abi.encodePacked("0"))
        ) {
            modalHash = string(
                abi.encodePacked(
                    "QmcDnBi5PT223FmELECbZVTjitFUtTvaBoctDP88ESuAK4"
                )
            );
            classification = 0;
        }
        if (
            keccak256(abi.encodePacked(classificationResult)) ==
            keccak256(abi.encodePacked("1"))
        ) {
            modalHash = string(
                abi.encodePacked(
                    "QmYbVUfuZq9ZA5rdbfKHs2LNMHQ7jCzLJmwHHeGqVaXmSQ"
                )
            );
            classification = 1;
        }
        if (
            keccak256(abi.encodePacked(classificationResult)) ==
            keccak256(abi.encodePacked("2"))
        ) {
            modalHash = string(
                abi.encodePacked(
                    "QmXLNp8wHnjJHLHsUwJfxRSnAQhptUcMFsQJV9ouXQcPhr"
                )
            );
            classification = 2;
        } else {
            modalHash = string(
                abi.encodePacked(
                    "QmcDnBi5PT223FmELECbZVTjitFUtTvaBoctDP88ESuAK4"
                )
            );
            classification = 0;
        }
        classificationResultByAddress[tokenAddress] = classification;
        emit ClassificationResultUpdate(tokenAddress, classification);

        bytes32 result = inferCall(modalHash, inputData);
        uint256 riskMetric = stringToInt(string(abi.encodePacked(result)), 6);
        riskMetricByAddress[tokenAddress] = riskMetric;
        emit RiskMetricUpdate(tokenAddress, riskMetric);
    }

    function getClassificationResultcByAddress(
        address _tokenAddress
    ) public view returns (uint256) {
        return classificationResultByAddress[_tokenAddress];
    }

    function getRiskMetricByAddress(
        address _tokenAddress
    ) public view returns (uint256) {
        return riskMetricByAddress[_tokenAddress];
    }
}
