
// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract RPSLP {
    uint public numPlayer = 0;
    uint public reward = 0;
    mapping (address => uint) public player_choice; // 0 - Rock, 1 - Paper , 2 - Scissors, 3 - Lizard, 4 - Spock
    mapping(address => bool) public player_not_played;
    address[] public players;

    uint public numInput = 0;

    function addPlayer() public payable {
        require(numPlayer < 2);
        if (numPlayer > 0) {
            require(msg.sender != players[0]);
        }
        require(msg.value == 1 ether);
        reward += msg.value;
        player_not_played[msg.sender] = true;
        players.push(msg.sender);
        numPlayer++;
    }

    function input(uint choice) public  {
        require(numPlayer == 2);
        require(player_not_played[msg.sender]);
        require(choice == 0 || choice == 1 || choice == 2 || choice == 3 || choice == 4);
        player_choice[msg.sender] = choice;
        player_not_played[msg.sender] = false;
        numInput++;
        if (numInput == 2) {
            _checkWinnerAndPay();
        }
    }

    function _checkWinnerAndPay() private {
        uint p0Choice = player_choice[players[0]];
        uint p1Choice = player_choice[players[1]];
        address payable account0 = payable(players[0]);
        address payable account1 = payable(players[1]);

        if (_isWinner(p0Choice, p1Choice)) {
            account0.transfer(reward);
        } 
        else if (_isWinner(p1Choice, p0Choice)) {
            account1.transfer(reward);
        } 
        else {
            // Tie case, split reward
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
}