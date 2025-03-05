// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./TimeUnit.sol";
import "./CommitReveal.sol";

contract RPSLS is TimeUnit {
    CommitReveal public commitContract;
    
    uint public numPlayer = 0;
    uint public reward = 0;
    mapping(address => uint) public player_choice;
    mapping(address => bool) public player_not_played;
    address[] public players;
    uint public numInput = 0;

    address[] private allowedAccounts = [
        0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
        0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
        0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,
        0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
    ];

    constructor(address _commitContract) {
        commitContract = CommitReveal(_commitContract);
    }

    modifier onlyAllowedAccounts() {
        bool isAllowed = false;
        for (uint i = 0; i < allowedAccounts.length; i++) {
            if (msg.sender == allowedAccounts[i]) {
                isAllowed = true;
                break;
            }
        }
        require(isAllowed, "Not an allowed account.");
        _;
    }

    function addPlayer() public payable onlyAllowedAccounts {
        require(numPlayer < 2, "Already 2 players.");
        require(msg.value == 1 ether, "Must send 1 ETH.");
        
        if (numPlayer > 0) {
            require(msg.sender != players[0]);
        }

        reward += msg.value;
        player_not_played[msg.sender] = true;
        players.push(msg.sender);
        numPlayer++;

        updateActionTime();
    }

    function commit(bytes32 dataHash) public onlyAllowedAccounts {
        require(player_not_played[msg.sender], "Not registered or already committed.");
        commitContract.commit(dataHash);
    }

    function reveal(string memory randomSalt, uint choice) public onlyAllowedAccounts {
        require(player_not_played[msg.sender], "Not registered or already revealed.");
        require(commitContract.reveal(randomSalt, choice), "Invalid reveal.");

        player_choice[msg.sender] = choice;
        player_not_played[msg.sender] = false;
        numInput++;

        if (numInput == 2) {
            _checkWinnerAndPay();
        }

        updateActionTime();
    }

    function _checkWinnerAndPay() private {
        uint p0Choice = player_choice[players[0]];
        uint p1Choice = player_choice[players[1]];
        address payable account0 = payable(players[0]);
        address payable account1 = payable(players[1]);

        if (_isWinner(p0Choice, p1Choice)) {
            account0.transfer(reward);
        } else if (_isWinner(p1Choice, p0Choice)) {
            account1.transfer(reward);
        } else {
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        }
    }

    function _isWinner(uint choice1, uint choice2) private pure returns (bool) {
        return (
            (choice1 == 0 && (choice2 == 2 || choice2 == 3)) ||
            (choice1 == 1 && (choice2 == 0 || choice2 == 4)) ||
            (choice1 == 2 && (choice2 == 1 || choice2 == 3)) ||
            (choice1 == 3 && (choice2 == 1 || choice2 == 4)) ||
            (choice1 == 4 && (choice2 == 0 || choice2 == 2))
        );
    }

    function refund() public onlyAllowedAccounts {
        require(numPlayer > 0, "No active game.");
        require(reward > 0, "No reward available.");

        address payable account0 = payable(players[0]);

        if (numPlayer == 1) {
            require(msg.sender == players[0], "Only player can refund.");
            account0.transfer(reward);
        } else if (numPlayer == 2) {
            require(msg.sender == players[0] || msg.sender == players[1], "Only players can refund.");
            address payable account1 = payable(players[1]);
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        }

        _resetGame();
    }

    function _resetGame() private {
        numPlayer = 0;
        numInput = 0;
        reward = 0;

        for (uint i = 0; i < players.length; i++) {
            delete player_choice[players[i]];
            delete player_not_played[players[i]];
        }

        delete players;
        updateActionTime();
    }
}
