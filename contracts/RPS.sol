// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract RPS {
  struct Player {
    uint choice; // 0 - Rock, 1 - Paper , 2 - Scissors, 3 - undefined
    bytes32 commit;
    address addr;
  }
  uint public reward = 0;
  Player public player0;
  Player public player1;
  uint public numPlayer = 0;
  uint public numInput = 0;
  uint public inputDeadline = 0;
  uint public numReveal = 0;
  uint public revealDeadline = 0;
  uint public duration = 3 minutes;

  function addPlayer() public payable {
    require(numPlayer < 2);
    require(msg.value == 1 ether);
    if (inputDeadline == 0) {
      inputDeadline = block.timestamp + duration;
    }
    reward += msg.value;
    numPlayer++;
    if (player0.addr == address(0x0)) {
      player0.addr = msg.sender;
      player0.choice = 3;
      player0.commit = 0;
      return;
    } else if (player1.addr == address(0x0)) {
      player1.addr = msg.sender;
      player1.choice = 3;
      player1.commit = 0;
      return;
    }
  }

  function input(bytes32 hashChoice) public {
    require(numPlayer == 2);
    require(numInput < 2);
    require(block.timestamp < inputDeadline);
    if (msg.sender == player0.addr) {
      require(player0.choice == 3); // not yet revealed
      require(player0.commit == 0); // not yet committed
      player0.commit = hashChoice;
    } else if (msg.sender == player1.addr) {
      require(player1.choice == 3); // not yet revealed
      require(player1.commit == 0); // not yet committed
      player1.commit = hashChoice;
    }
    numInput++;
    if (numInput == 2) {
      revealDeadline = block.timestamp + duration;
    }
  }

  function reveal(uint choice, string memory password) public {
    require(numInput == 2);
    require(numReveal < 2);
    require(block.timestamp < revealDeadline);
    if (msg.sender == player0.addr) {
      require(player0.choice == 3); // not yet revealed
      require(player0.commit != 0); // already committed
      require(keccak256(abi.encodePacked(choice, password)) == player0.commit);
      player0.choice = choice;
    } else if (msg.sender == player1.addr) {
      require(player1.choice == 3); // not yet revealed
      require(player1.commit != 0); // already committed
      require(keccak256(abi.encodePacked(choice, password)) == player1.commit);
      player1.choice = choice;
    }
    numReveal++;
    if (numReveal == 2) {
      _checkWinnerAndPay();
    }
  }

  function _checkWinnerAndPay() private {
    uint p0Choice = player0.choice;
    uint p1Choice = player1.choice;
    address payable account0 = payable(player0.addr);
    address payable account1 = payable(player1.addr);
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
    reward = 0;
    _resetStage();
  }

  function _resetStage() private {
    player0.choice = 3;
    player1.choice = 3;
    player0.commit = 0;
    player1.commit = 0;
    player0.addr = address(0x0);
    player1.addr = address(0x0);
    numPlayer = 0;
    numInput = 0;
    numReveal = 0;
    inputDeadline = 0;
    revealDeadline = 0;
  }

  function getHash(
    uint choice,
    string memory password
  ) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(choice, password));
  }

  function claimReward() public {
    require(msg.sender == player0.addr || msg.sender == player1.addr);
    // if there are no other player, the player can claim the reward
    address payable account = payable(msg.sender);
    Player memory p;
    if (msg.sender == player0.addr) {
      p = player0;
    } else if (msg.sender == player1.addr) {
      p = player1;
    }
    // if the others player has not input the choice, the player can claim the reward
    if (numPlayer < 2) {
      account.transfer(reward);
    }
    // if the others player has not input the choice, the player can claim the reward
    else if (numInput < 2) {
      require(block.timestamp > inputDeadline);
      require(p.choice == 3 && p.commit != 0);
      account.transfer(reward);
    }
    // if the others player has not reveal the choice, the player can claim the reward
    else if (numReveal < 2) {
      require(block.timestamp > revealDeadline);
      require(p.choice != 3);
      account.transfer(reward);
    }
    reward = 0;
    _resetStage();
  }
}
