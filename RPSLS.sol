// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./CommitReveal.sol";
import "./TimeUnit.sol";

contract RPSLS{

    CommitReveal public commitReveal;
    TimeUnit public timeUnit;

    uint public numPlayer = 0;
    uint public reward = 0;
    mapping(address => uint) public player_choice; // 0 - Rock, 1 - Paper , 2 - Scissors, 3 - Lizard, 4 - Spock
    address[] public players;

    uint public numCommits = 0;
    uint public numReveals = 0;

    event PlayerAdded(address indexed player);
    event Winner(address indexed winner, uint amount);
    event GameReset();

    constructor() {
        commitReveal = new CommitReveal();
        timeUnit = new TimeUnit();  
    }


    modifier onlyAllowedAccounts() {
        require(
            msg.sender == 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4 ||
            msg.sender == 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 ||
            msg.sender == 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db ||
            msg.sender == 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB,
            "Unauthorized account"
        );
        _;
    }

    function addPlayer() public payable onlyAllowedAccounts {
        require(numPlayer < 2, "Already 2 players.");
        require(msg.value == 1 ether, "Must send 1 ETH.");

        if (numPlayer > 0) {
            require(msg.sender != players[0], "Player already added.");
        }

        reward += msg.value;
        players.push(msg.sender);
        numPlayer++;

        timeUnit.updateActionTime();
        emit PlayerAdded(msg.sender);
    }

    function inputCommit(bytes32 commitHash) public {
        require(numPlayer == 2, "Game is not ready.");

        commitReveal.commit(commitHash, msg.sender);
        numCommits++;

        timeUnit.updateActionTime();
    }

    function revealChoice(bytes32 revealHash) public {
        require(numCommits == 2, "Both players must commit before revealing.");

        commitReveal.reveal(revealHash, msg.sender);
        uint8 choiceFromHash = getChoiceFromHash(revealHash);
        player_choice[msg.sender] = choiceFromHash;
        numReveals++;

        if (numReveals == 2) {
            _checkWinnerAndPay();
        }

        timeUnit.updateActionTime();
    }

    function getChoiceFromHash(bytes32 revealHash) public pure returns (uint8) {
        uint8 choice = uint8(revealHash[revealHash.length - 1]) % 5;
        return choice;
    }

    function _checkWinnerAndPay() private {
        uint p0Choice = player_choice[players[0]];
        uint p1Choice = player_choice[players[1]];
        address payable account0 = payable(players[0]);
        address payable account1 = payable(players[1]);

        if (_isWinner(p0Choice, p1Choice)) {
            account0.transfer(reward);
            emit Winner(account0, reward);
        } 
        else if (_isWinner(p1Choice, p0Choice)) {
            account1.transfer(reward);
            emit Winner(account1, reward);
        } 
        else {
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        }

        _resetGame();
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

    function refund() public {
        require(timeUnit.isTimeExceeded(), "Refund period not elapsed");
        require(numPlayer > 0, "No active game");

        address payable account0 = payable(players[0]);

        if (numPlayer == 1) {
            require(msg.sender == players[0], "Only player can refund");
            account0.transfer(reward);
        } else {
            require(msg.sender == players[0] || msg.sender == players[1], "Unauthorized refund");
            address payable account1 = payable(players[1]);
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        }

        _resetGame();
    }

    function _resetGame() private {
        numPlayer = 0;
        reward = 0;
        numCommits = 0;
        numReveals = 0;
        
        emit GameReset();

        for (uint i = 0; i < players.length; i++) {
            delete player_choice[players[i]];
        }

        delete players;
    }
}
