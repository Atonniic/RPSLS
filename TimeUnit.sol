// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract TimeUnit {
    uint public latestActionTime = block.timestamp;
    uint public constant delayTime = 1 minutes; // กำหนด delay เป็น 1 นาที

    // ฟังก์ชันสำหรับอัปเดตเวลาล่าสุดที่มีการกระทำ
    function updateActionTime() internal {
        latestActionTime = block.timestamp;
    }

    // ฟังก์ชันตรวจสอบเวลาที่ผ่านไปตั้งแต่การกระทำล่าสุด
    function elapsedSeconds() public view returns (uint256) {
        return block.timestamp - latestActionTime;
    }

    // ฟังก์ชันตรวจสอบว่าเวลาครบกำหนดหรือยัง
    function isTimeout() public view returns (bool) {
        return (block.timestamp - latestActionTime) > delayTime;
    }
}
