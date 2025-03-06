// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./CommitReveal.sol";
import "./TimeUnit.sol";
contract RPS is CommitReveal, TimeUnit {
    enum Choice {
        Scissors,
        Paper,
        Rock,
        Lizard,
        Spock
    }
    uint public constant TIME_LIMIT = 1 minutes;
    address[] public allowedPlayerList = [
        0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
        0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
        0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,
        0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
    ];

    uint public numPlayer = 0;
    uint public numInput = 0;
    uint public numReveal = 0;
    uint public reward = 0;
    mapping(address => Choice) public player_choice;
    mapping(address => bytes32) public player_hashedChoice;
    mapping(address => bool) public player_not_played;
    address[] public players;

    function addPlayer() public payable {
        require(numPlayer < 2);
        if (numPlayer > 0) {
            require(msg.sender != players[0]);
        }
        // Player must be in allowedPlayerList
        bool isAllowed = false;
        for (uint i = 0; i < allowedPlayerList.length; i++) {
            if (msg.sender == allowedPlayerList[i]) {
                isAllowed = true;
                break;
            }
        }
        require(isAllowed);

        if (numPlayer == 0) {
            _setStartTime();
        } else if (numPlayer > 0) {
            require(elapsedMinutes() < TIME_LIMIT);
        }

        require(msg.value == 1 ether);
        reward += msg.value;
        player_not_played[msg.sender] = true;
        players.push(msg.sender);
        numPlayer++;
    }

    function getHashedChoice(
        Choice choice,
        string memory secret
    ) public pure returns (bytes32) {
        return getHash(bytes32(abi.encodePacked(choice, secret)));
    }

    function inputHashedChoice(bytes32 hashedChoice) public {
        require(numPlayer == 2);
        require(player_not_played[msg.sender]);
        require(elapsedSeconds() < TIME_LIMIT);

        commit(hashedChoice);
        player_hashedChoice[msg.sender] = hashedChoice;
        player_not_played[msg.sender] = false;
        numInput++;
    }

    function revealChoice(Choice choice, string memory secret) public {
        require(numPlayer == 2);
        require(!player_not_played[msg.sender]);
        require(!commits[msg.sender].revealed);
        require(
            choice == Choice.Scissors ||
                choice == Choice.Paper ||
                choice == Choice.Rock ||
                choice == Choice.Lizard ||
                choice == Choice.Spock
        );
        require(elapsedSeconds() < TIME_LIMIT);

        reveal(bytes32(abi.encodePacked(choice, secret)));
        player_choice[msg.sender] = choice;
        numReveal++;
        if (numReveal == 2) {
            _checkWinnerAndPay();
            _resetGame();
        }
    }

    function _checkWinnerAndPay() private {
        require(numReveal == 2);
        Choice p0Choice = player_choice[players[0]];
        Choice p1Choice = player_choice[players[1]];
        address payable account0 = payable(players[0]);
        address payable account1 = payable(players[1]);
        if (
            (uint(p1Choice) + 1) % 5 == uint(p0Choice) ||
            (uint(p1Choice) + 3) % 5 == uint(p0Choice)
        ) {
            // to pay player[1]
            account1.transfer(reward);
        } else if (
            (uint(p0Choice) + 1) % 5 == uint(p1Choice) ||
            (uint(p0Choice) + 3) % 5 == uint(p1Choice)
        ) {
            // to pay player[0]
            account0.transfer(reward);
        } else {
            // to split reward
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        }
    }

    function withdraw() public {
        require(elapsedSeconds() >= TIME_LIMIT);
        require(numPlayer > 0);

        // Case 1: Only 1 player join
        if (numPlayer == 1) {
            address payable account0 = payable(players[0]);
            account0.transfer(reward);
        }
        // Case 2: 2 players join
        else if (numPlayer == 2) {
            address payable account0 = payable(players[0]);
            address payable account1 = payable(players[1]);

            // Case not play
            if (
                player_not_played[players[0]] && player_not_played[players[1]]
            ) {
                // split reward if both player not play
                account0.transfer(reward / 2);
                account1.transfer(reward / 2);
            } else if (player_not_played[players[0]]) {
                account1.transfer(reward);
            } else if (player_not_played[players[1]]) {
                account0.transfer(reward);
            }
            // Case not reveal
            else if (
                commits[players[0]].revealed && commits[players[1]].revealed
            ) {
                // split reward if both player not reveal
                account0.transfer(reward / 2);
                account1.transfer(reward / 2);
            } else if (commits[players[0]].revealed) {
                account1.transfer(reward);
            } else if (commits[players[1]].revealed) {
                account0.transfer(reward);
            }
        }

        _resetGame();
    }

    function _resetGame() private {
        numPlayer = 0;
        numReveal = 0;
        reward = 0;
        numInput = 0;
        delete players;
        for (uint i = 0; i < allowedPlayerList.length; i++) {
            player_not_played[allowedPlayerList[i]] = false;
        }
    }

    function secondsUntilWithdrawableTime() public view returns (uint) {
        if (numPlayer == 0) {
            return 0;
        }
        if (elapsedSeconds() >= TIME_LIMIT) {
            return 0;
        }
        return TIME_LIMIT - elapsedSeconds();
    }
}
