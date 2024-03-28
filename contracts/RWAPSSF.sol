// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./CommitReveal.sol";

contract RPS is CommitReveal {
  struct Player {
    uint256 choice0; // 0 - Rock, 1 - water , 2 -Air, 3-Paper, 4-sponge, 5-Scissors, 6-Fire, 7-unrevealed
    uint256 choice1; // 0 - Rock, 1 - water , 2 -Air, 3-Paper, 4-sponge, 5-Scissors, 6-Fire, 7-unrevealed
    bool commit; // true - committed, false - not yet committed
    address addr;
  }
  uint public constant unrevealChoice = 7;
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
    reward += msg.value;
    numPlayer++;
    // set deadline for input when the second player join
    if (numPlayer == 2) {
      inputDeadline = block.timestamp + duration;
    }
    Player storage p;
    if (player0.addr == address(0x0)) {
      p = player0;
    } else {
      p = player1;
    }
    p.addr = msg.sender;
    p.choice0 = unrevealChoice;
    p.choice1 = unrevealChoice;
    p.commit = false;
  }

  function input(bytes32 hashChoice) public {
    require(numPlayer == 2);
    require(numInput < 2);
    require(block.timestamp < inputDeadline);
    Player storage p;
    if (player0.addr == msg.sender) {
      p = player0;
    } else {
      p = player1;
    }
    require(p.commit == false);
    p.commit = true;
    commit(hashChoice);
    numInput++;
    if (numInput == 2) {
      revealDeadline = block.timestamp + duration;
    }
  }

  function revealChoice(
    uint choice1,
    uint choice2,
    string memory password
  ) public {
    require(numInput == 2);
    require(numReveal < 2);
    require(block.timestamp < revealDeadline);
    require(msg.sender == player0.addr || msg.sender == player1.addr);
    Player storage p;
    if (msg.sender == player0.addr) {
      p = player0;
    } else {
      p = player1;
    }
    revealAnswer(choice1, choice2, password);
    numReveal++;
    p.choice0 = choice1;
    p.choice1 = choice2;
    if (numReveal == 2) {
      _checkWinnerAndPay();
    }
  }

  function _checkWinnerAndPay() private {
    uint p0Choice0 = player0.choice0;
    uint p0Choice1 = player0.choice1;

    uint p1Choice0 = player1.choice0;
    uint p1Choice1 = player1.choice1;
    address payable account0 = payable(player0.addr);
    address payable account1 = payable(player1.addr);

    uint p0Point = 0;
    uint p1Point = 0;
    if (p0Choice0 == p1Choice0) {
      p0Point++;
      p1Point++;
    } else if (
      ((p0Choice0 + 1) % unrevealChoice) == p1Choice0 ||
      ((p0Choice0 + 2) % unrevealChoice) == p1Choice0 ||
      ((p0Choice0 + 3) % unrevealChoice) == p1Choice0
    ) {
      p1Point += 2;
    } else {
      p0Point += 2;
    }
    if (p0Choice1 == p1Choice1) {
      p0Point++;
      p1Point++;
    } else if (
      ((p0Choice1 + 1) % unrevealChoice) == p1Choice1 ||
      ((p0Choice1 + 2) % unrevealChoice) == p1Choice1 ||
      ((p0Choice1 + 3) % unrevealChoice) == p1Choice1
    ) {
      p1Point += 2;
    } else {
      p0Point += 2;
    }

    if (p1Point == p0Point) {
      // to split reward
      account0.transfer(reward / 2);
      account1.transfer(reward / 2);
    } else if (p1Point > p0Point) {
      // to pay player[1]
      account1.transfer(reward);
    } else {
      // to pay player0
      account0.transfer(reward);
    }
    reward = 0;
    _resetStage();
  }

  function _resetStage() private {
    player0.addr = address(0x0);
    player1.addr = address(0x0);
    numPlayer = 0;
    numInput = 0;
    numReveal = 0;
    inputDeadline = 0;
    revealDeadline = 0;
  }

  function claimReward() public {
    require(msg.sender == player0.addr || msg.sender == player1.addr);
    address payable account = payable(msg.sender);
    Player memory p;
    if (msg.sender == player0.addr) {
      p = player0;
    } else if (msg.sender == player1.addr) {
      p = player1;
    }
    // if there are no other player, the player can claim the reward
    if (numPlayer < 2) {
      account.transfer(reward);
    }
    // if the others player has not input the choice, the player can claim the reward
    else if (numInput < 2) {
      require(block.timestamp > inputDeadline);
      require(
        p.choice0 == unrevealChoice &&
          p.choice1 == unrevealChoice &&
          p.commit != false
      );
      account.transfer(reward);
    }
    // if the others player has not reveal the choice, the player can claim the reward
    else if (numReveal < 2) {
      require(block.timestamp > revealDeadline);
      require(p.choice0 != unrevealChoice && p.choice1 != unrevealChoice);
      account.transfer(reward);
    }
    reward = 0;
    _resetStage();
  }

  function timeLeft() public view returns (string memory stage, uint time) {
    if (numPlayer < 2) {
      return ("Wait for players", 0);
    } else if (numInput < 2) {
      if (inputDeadline > block.timestamp) {
        return ("Time left to input", inputDeadline - block.timestamp);
      }
      return ("Exceed input time", 0);
    } else if (numReveal < 2) {
      if (revealDeadline > block.timestamp) {
        return ("Time left to reveal", revealDeadline - block.timestamp);
      }
      return ("Exceed reveal time", 0);
    } else {
      return ("Game over", 0);
    }
  }
}
