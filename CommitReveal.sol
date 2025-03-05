// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract CommitReveal {
    struct Commit {
        bytes32 commitHash;
        uint256 blockNumber;
        bool revealed;
    }

    mapping(address => Commit) public commits;

    event CommitHash(address sender, bytes32 commit, uint256 block);

    function commit(bytes32 dataHash) public {
        commits[msg.sender] = Commit(dataHash, block.number, false);
        emit CommitHash(msg.sender, dataHash, block.number);
    }

    function reveal(string memory randomSalt, uint choice) public returns (bool) {
        require(commits[msg.sender].commitHash != 0, "No commitment found.");
        require(!commits[msg.sender].revealed, "Already revealed.");

        bytes32 checkHash = keccak256(abi.encodePacked(randomSalt, choice));
        require(checkHash == commits[msg.sender].commitHash, "Commitment mismatch.");

        commits[msg.sender].revealed = true;
        return true;
    }
}
