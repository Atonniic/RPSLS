// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./CommitReveal.sol";
import "./TimeUnit.sol";
import "./IERC20.sol";

contract RPSLS {
    CommitReveal public commitReveal;
    TimeUnit public timeUnit;
    IERC20 public token;

    uint public numPlayer = 0;
    uint public reward = 0;
    mapping(address => uint) public player_choice; // 0 - Rock, 1 - Paper , 2 - Scissors, 3 - Lizard, 4 - Spock
    address[] public players;
    uint public numCommits = 0;
    uint public numReveals = 0;
    uint public constant BET_AMOUNT = 0.000001 ether;
    
    event PlayerAdded(address indexed player);
    event Winner(address indexed winner, uint amount);
    event GameReset();
    event Forfeit(address indexed winner, uint amount);

    constructor(address _token) {
        commitReveal = new CommitReveal();
        timeUnit = new TimeUnit();  
        token = IERC20(_token);
    }

    function addPlayer() public {
        require(numPlayer < 2, "Already 2 players.");
        require(token.allowance(msg.sender, address(this)) >= BET_AMOUNT, "Insufficient allowance.");

        if (numPlayer > 0) {
            require(msg.sender != players[0], "Player already added.");
        }

        players.push(msg.sender);
        numPlayer++;

        emit PlayerAdded(msg.sender);
    }

    function inputCommit(bytes32 commitHash) public {
        require(numPlayer == 2, "Game is not ready.");
        require(token.allowance(players[0], address(this)) >= BET_AMOUNT, "Player 1 hasn't approved the bet.");
        require(token.allowance(players[1], address(this)) >= BET_AMOUNT, "Player 2 hasn't approved the bet.");
        require(numCommits < 2, "Already committed.");

        commitReveal.commit(commitHash, msg.sender);
        numCommits++;

        if (numCommits == 2) {
            // Transfer funds from both players
            require(token.transferFrom(players[0], address(this), BET_AMOUNT), "Player 1 bet failed.");
            require(token.transferFrom(players[1], address(this), BET_AMOUNT), "Player 2 bet failed.");
            reward = BET_AMOUNT * 2;
        }
        
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
        return uint8(revealHash[revealHash.length - 1]) % 5;
    }

    function _checkWinnerAndPay() private {
        uint p0Choice = player_choice[players[0]];
        uint p1Choice = player_choice[players[1]];
        address payable account0 = payable(players[0]);
        address payable account1 = payable(players[1]);

        if (_isWinner(p0Choice, p1Choice)) {
            token.transfer(account0, reward);
            emit Winner(account0, reward);
        } else if (_isWinner(p1Choice, p0Choice)) {
            token.transfer(account1, reward);
            emit Winner(account1, reward);
        } else {
            token.transfer(account0, reward / 2);
            token.transfer(account1, reward / 2);
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

    function claimForfeit() public {
        require(timeUnit.isTimeExceeded(), "Reveal period not elapsed");
        require(numReveals < 2, "Game already revealed");

        address winner;
        if (numReveals == 1) {
            winner = (player_choice[players[0]] != 0) ? players[0] : players[1];
        } else {
            winner = msg.sender;
        }

        token.transfer(winner, reward);
        emit Forfeit(winner, reward);
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
