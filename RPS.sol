// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract RPS {
    uint public numPlayer = 0;
    uint public reward = 0;
    mapping(address => uint) public player_choice; // 0 - Rock, 1 - Paper , 2 - Scissors
    mapping(address => bool) public player_not_played;
    address[] public players;
    address[] public allowedPlayerList = [
        0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
        0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
        0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,
        0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
    ];

    uint public numInput = 0;

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
        require(msg.value == 1 ether);
        reward += msg.value;
        player_not_played[msg.sender] = true;
        players.push(msg.sender);
        numPlayer++;
    }

    function input(uint choice) public {
        require(numPlayer == 2);
        require(player_not_played[msg.sender]);
        require(choice == 0 || choice == 1 || choice == 2);
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
        if ((p0Choice + 1) % 3 == p1Choice) {
            // to pay player[1]
            account1.transfer(reward);
        } else if ((p1Choice + 1) % 3 == p0Choice) {
            // to pay player[0]
            account0.transfer(reward);
        } else {
            // to split reward
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        }
    }
}
