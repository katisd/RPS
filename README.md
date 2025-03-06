# Rock Paper Scissors (RPS) Game

## Introduction

Welcome to the Rock Paper Scissors Lizard Spock (RPSLS) game! This project implements a decentralized version of the classic game using smart contracts. Players can engage in a fair and transparent game, with additional features to enhance the gaming experience.

## Game Rules

1. Each player chooses one of the five options: Rock, Paper, Scissors, Lizard, or Spock.
2. The choices are revealed simultaneously.
3. The winner is determined based on the following rules:

- Rock crushes Scissors
- Scissors cuts Paper
- Paper covers Rock
- Rock crushes Lizard
- Lizard poisons Spock
- Spock smashes Scissors
- Scissors decapitates Lizard
- Lizard eats Paper
- Paper disproves Spock
- Spock vaporizes Rock
  <!-- Image -->
  ![RPSLS](./statics/RPSLS.png)

## Game Flow

1. **Player Registration**: Players register by sending a transaction to the smart contract.
2. **Commit Phase**: Each player commits their move by sending a hashed version of their choice.
3. **Reveal Phase**: Players reveal their moves by sending the original choice that matches the hash.
4. **Determine Winner**: The smart contract determines the winner based on the revealed moves.

## Additional Features

- **Allowed Players Set**: Only allowed set of players can participate in the game.

```sol
    address[] public allowedPlayerList = [
        0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
        0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
        0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,
        0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
    ];
```

- **Commit-Reveal Scheme**: Prevents front-running by allowing players to commit their moves in a hashed form and reveal them later.
- **Withdraw Function**: Ensures that players can withdraw their tokens after a set of time has passed (Currently 1 minutes) to prevent them from being locked in the contract. We also have penalty for player who didn't action within the proper time

## Examples

### Success Case

1. Player A and Player B register.
2. Player A commits their move (e.g., hashed Rock).
3. Player B commits their move (e.g., hashed Scissors).
4. Player A reveals their move (Rock).
5. Player B reveals their move (Scissors).
6. The contract determines Player A as the winner and transfers the stakes.

### Even Case

1. Player A and Player B register.
2. Player A commits their move (e.g., hashed Rock).
3. Player B commits their move (e.g., hashed Rock).
4. Player A reveals their move (Rock).
5. Player B reveals their move (Rock).
6. The contract determines the game is a draw. Both players will get their stakes back.

### Withdraw Case: No Other Player Joins

1. Player A registers.
2. After 1 minute, No other player joints
3. Player A can withdraw their stakes.

### Withdraw Case: Other Player Joins but not commit

1. Player A and Player B register.
1. Player A commits their move (e.g., hashed Rock).
1. After 1 minute, Player B didn't commit
1. Player A can withdraw their stakes.

### Withdraw Case: Other Player Joins and commit but not reveal

1. Player A and Player B register.
1. Player A commits their move (e.g., hashed Rock).
1. Player B commits their move (e.g., hashed Scissors).
1. Player A reveals their move (Rock).
1. After 1 minute, Player B didn't reveal
1. Player A can withdraw their stakes.
