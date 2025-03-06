// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract TimeUnit {
    uint public latestActionTime;
    uint public constant delayTime = 1 minutes;

    function updateActionTime() public {
        latestActionTime = block.timestamp;
    }

    function isTimeExceeded() public view returns (bool) {
        return (block.timestamp - latestActionTime) > delayTime;
    }
}
