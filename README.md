<!-- TOC start (generated with https://github.com/derlin/bitdowntoc) -->
<!-- TOC --><a name="optimize-rps"></a>
# Optimize RPS

   * [Problem](#problem)
   * [Solution](#solution)
      + [Front running](#front-running)
      + [Identify the player](#identify-the-player)
      + [Tokens can be stuck on the contract](#tokens-can-be-stuck-on-the-contract)
      + [Can play 1 time after being deployed.](#can-play-1-time-after-being-deployed)
   * [Additional](#additional)
      + [Timed commitment](#timed-commitment)
      + [Extened choice](#extened-choice)

<!-- TOC end -->


<!-- TOC --><a name="problem"></a>
## Problem
1. Front-running
2. Currently use idx to identify the player (player needs to send idx along with choice)
3. Tokens can be stuck on the contract in cases
     1. If there is only one player. They'll have to wait forever for another player to join.
     2. If only 1 player reveals their choice.
4. Can play 1 time after being deployed.
<!-- TOC --><a name="solution"></a>
## Solution
<!-- TOC --><a name="front-running"></a>
### Front running
With front running, we can commit and reveal to ensure that other players won't know the player's choice before revealing.
1. In this project, I decided to edit CommitReveal.sol to make the function internal and change the datatype for simplicity. [commit](https://github.com/katisd/RPS/commit/d7c9d53693fa205e94e4de8236f9654326ddf255)
2. Change the input function to accept a hash of choice(bytes32)
3. Make sure that player can reveal their answer after all players commit their choice.
4. Then after everyone reveals their choice, Check for the winner.
```solidity
  function input(bytes32 hashChoice) public {    // input accept hash choice
    require(numPlayer == 2);
    require(numInput < 2);
    ...
    commit(hashChoice);                          //commit has choice
    ...
  }

  function revealChoice(uint choice, string memory password) public {
    require(numInput == 2);                      // can reveal after everyone already commit choice
    ...
    if (numReveal == 2) {                        // if everyone reveal answer -> check for winner
      _checkWinnerAndPay();
    }
  }

```
<!-- TOC --><a name="identify-the-player"></a>
### Identify the player
I use the sender's address as an identifier of the player. It's hard to scale a number of players up, but that's not the case here.
<!-- TOC --><a name="tokens-can-be-stuck-on-the-contract"></a>
### Tokens can be stuck on the contract
1. We can have a function in case there is only one plyer nad they want to retrieve a token and end the game round.
2. We can do timed commitment so if players are unwilling to commit or reveal a choice in time, other players can claim all tokens. (In this case, there are 2 players so others will get all the money)
```solidity
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
      require(p.choice == unrevealChoice && p.commit != false);
      account.transfer(reward);
    }
    // if the others player has not reveal the choice, the player can claim the reward
    else if (numReveal < 2) {
      require(block.timestamp > revealDeadline);
      require(p.choice != unrevealChoice);
      account.transfer(reward);
    }
    reward = 0;
    _resetStage();
  }
```
<!-- TOC --><a name="can-play-1-time-after-being-deployed"></a>
### Can play 1 time after being deployed.
Since there is no resetting, so we can't replay this contract. We can have the resetStage function to reset the value and call it after finding a winner or someone claiming the tokens.
```solidity
  function _resetStage() private {
    player0.addr = address(0x0);
    player1.addr = address(0x0);
    numPlayer = 0;
    numInput = 0;
    numReveal = 0;
    inputDeadline = 0;
    revealDeadline = 0;
  }

  function _checkWinnerAndPay() private {
    ...
    _resetStage();
  }

  function claimReward() public {
    ...
    _resetStage();
  }
```
<!-- TOC --><a name="additional"></a>
## Additional
<!-- TOC --><a name="timed-commitment"></a>
### Timed commitment
Since we do timed commitment as mentioned. I also provided a timeLeft function for player to know stage and time left for commit or reveal.
```solidity
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
```
<!-- TOC --><a name="extened-choice"></a>
### Extened choice
I also add more choice for player.
```
0 - Rock,
1 - water,
2 - Air,
3 - Paper,
4 - sponge,
5 - Scissors,
6 - Fire,
7 - unrevealed
```
![img](https://i.pinimg.com/564x/af/1f/ad/af1fadd6bdbf11a193fe9e4acce10dae.jpg) <br/>
As there are more choice, we need to change a rule for winner.
```solidity
  function _checkWinnerAndPay() private {
    uint p0Choice = player0.choice;
    uint p1Choice = player1.choice;
    address payable account0 = payable(player0.addr);
    address payable account1 = payable(player1.addr);
    if (p0Choice == p1Choice) {
      // to split reward
      account0.transfer(reward / 2);
      account1.transfer(reward / 2);
    } else if (((p0Choice - p1Choice) % 7) <= 3) {
      // to pay player0
      account0.transfer(reward);
    } else {
      // to pay player[1]
      account1.transfer(reward);
    }
    reward = 0;
    _resetStage();
  }
```
