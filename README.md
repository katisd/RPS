<!-- TOC start (generated with https://github.com/derlin/bitdowntoc) -->
<!-- TOC --><a name="optimize-rps"></a>

# Optimize RPS

- [Problem](#problem)
- [Solution](#solution)
  - [Front running](#front-running)
  - [Identify the player](#identify-the-player)
  - [Tokens can be stuck on the contract](#tokens-can-be-stuck-on-the-contract)
  - [Can play 1 time after being deployed.](#can-play-1-time-after-being-deployed)
- [Additional](#additional)
  - [Timed commitment](#timed-commitment)
  - [Extened choice](#extened-choice)
- [Example](#example)
  - [example 1 | win and lose](#example-1)
  - [example 2 | even](#example-2)

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

Since we do timed commitments as mentioned. I also provided a timeLeft function for players to know the stage and time left for commit or reveal.

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

### Extended choice

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
As there are more choices, we need to change the rule for the winner.

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
  } else if (
    ((p0Choice + 1) % unrevealChoice) == p1Choice ||
    ((p0Choice + 2) % unrevealChoice) == p1Choice ||
    ((p0Choice + 3) % unrevealChoice) == p1Choice
  ) {
    // to pay player[1]
    account1.transfer(reward);
  } else {
    // to pay player0
    account0.transfer(reward);
  }
  reward = 0;
  _resetStage();
}
```

<!-- TOC --><a name="example"></a>

## Example

<!-- TOC --><a name="example-1"></a>

### example 1 | player 1 chose 1(water), player 2 chose 5(Scissors) => Water rusts Scissors so player 1 should win

1. After adding 2 players, each player will send a hash of choice and salt which can be obtained from the getSaltedHash function as shown. <br/>
   ![player1](https://github.com/katisd/RPS/assets/90249534/e0de0de7-344b-44a1-a3df-ecead5cb7c48)
   ![player2](https://github.com/katisd/RPS/assets/90249534/f0f0f9af-e9f4-42c0-ad20-e31f5cca7551)

2. Reveal choice<br/>
   ![image](https://github.com/katisd/RPS/assets/90249534/d8700fd2-5ce3-4292-ba67-e47a944097ff)
   ![image](https://github.com/katisd/RPS/assets/90249534/6c10a8fe-6749-4c97-a3f5-a321902af066)

3. Result in player 2 losing 1 ETH to player 1 <br/>
![image](https://github.com/katisd/RPS/assets/90249534/2d403f80-6203-423f-92f4-ef3f8ab6fc8b)
<!-- TOC --><a name="example-2"></a>

### example 2 | player 1 and 2 chose 1(water) => It should be even and they get ETH back

1. After adding 2 players, each player will send a hash of choice and salt which can be obtained from the getSaltedHash function as shown. <br/>
   ![image](https://github.com/katisd/RPS/assets/90249534/88a54be8-4011-4609-bcd4-e7373a81314f)
   ![image](https://github.com/katisd/RPS/assets/90249534/88a54be8-4011-4609-bcd4-e7373a81314f)
2. After revealing answers since the results even each player will get 1 ETH back. <br/>
   ![image](https://github.com/katisd/RPS/assets/90249534/546a3842-a9af-4e3b-a746-8a29248fdb98)
   ![image](https://github.com/katisd/RPS/assets/90249534/51132820-c173-4c55-9468-cc6154748366)
