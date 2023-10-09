// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MathContract {
    uint256 public t;
    uint256 public x;
    uint256 public y;

    constructor(uint256 _t, uint256 _x, uint256 _y) {
        t = _t;
        x = _x;
        y = _y;
    }

    function findX3(uint256 y2) public view returns (uint256) {
        uint256 temp = t * (y + y2);
        if (temp > x) {
            uint256 x3 = temp - x;
            if (x3 <= x) {
                return x3;
            } else {
                return 1;
            }
        } else {
            return 0;
        }
    }

    function findY3(uint256 x2) public view returns (uint256) {
        uint256 temp = (x + x2) / t;
        if (temp > y) {
            uint256 y3 = temp - y;
            if (y3 <= y) {
                return y3;
            } else {
                return 1;
            }
        } else {
            return 0;
        }
    }
}
