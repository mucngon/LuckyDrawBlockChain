# Lucky Draw Smart Contract

A decentralized lucky draw system built on the Stacks blockchain using Clarity smart contract language. This contract allows users to participate in a lucky draw by paying an entry fee in STX, with winners selected using block-based randomness.

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Contract Structure](#contract-structure)
  - [Constants](#constants)
  - [Data Variables](#data-variables)
  - [Data Maps](#data-maps)
  - [Functions](#functions)
- [Usage](#usage)
  - [Starting a New Game](#starting-a-new-game)
  - [Joining the Draw](#joining-the-draw)
  - [Drawing a Winner](#drawing-a-winner)
  - [Emergency Functions](#emergency-functions)
- [Error Codes](#error-codes)
- [Security Considerations](#security-considerations)
- [License](#license)

## Overview
The Lucky Draw Smart Contract enables users to participate in a fair and transparent lucky draw on the Stacks blockchain. The contract owner can initiate a game, users can join by paying an entry fee in STX, and a winner is selected randomly based on block data once the maximum number of participants is reached or the game is ended early by the owner.
<img width="1332" height="590" alt="image" src="https://github.com/user-attachments/assets/db53b8e0-b50c-4573-8d5b-5a72efaad374" />

## Features
- **Configurable Game Settings**: Set entry fees and maximum participants for each round.
- **Random Winner Selection**: Uses block-based randomness for fair winner selection.
- **Prize Distribution**: Automatically distributes prizes with a 5% commission to the contract owner.
- **Emergency Functions**: Includes refund and withdrawal mechanisms for emergency situations.
- **Transparency**: All game data (participants, prizes, winners) is stored on-chain and accessible via read-only functions.

## Prerequisites
- **Stacks Blockchain**: Deploy on a Stacks network (mainnet or testnet).
- **STX Tokens**: Users need STX to pay entry fees.
- **Clarity Development Environment**: For deploying and interacting with the contract.
- **Stacks Wallet**: For managing STX transactions.

## Contract Structure

### Constants
- **CONTRACT_OWNER**: The principal who deploys the contract.
- **Error Codes**: Defined for various failure scenarios (e.g., `ERR_NOT_AUTHORIZED`, `ERR_GAME_ACTIVE`).
- **Default Entry Fee**: 1 STX (1,000,000 microSTX).
- **Default Maximum Participants**: 100.

### Data Variables
- **game-active**: Boolean indicating if a game is active.
- **entry-fee**: The cost to join a round (in microSTX).
- **max-participants**: Maximum number of participants per round.
- **current-round**: Tracks the current game round.
- **draw-block-height**: Block height used for randomness.
- **winner**: Stores the winner of the current round (optional principal).
- **total-prize**: Total prize pool for the current round.

### Data Maps
- **participants**: Stores participant details (round, principal, entry block, and amount).
- **participant-list**: Maps participants to their index in a round.
- **round-info**: Stores round-specific data (participant count, prize, winner, draw block, completion status).

### Functions
<img width="1331" height="516" alt="image" src="https://github.com/user-attachments/assets/1eaaf517-c135-4c83-9ae1-efff22e91bcd" />

#### Public Functions
- **start-new-game**: Initializes a new game with specified entry fee and max participants.
- **join-draw**: Allows users to join the current round by paying the entry fee.
- **end-game-early**: Allows the owner to end the game before reaching max participants.
- **draw-winner**: Selects a winner using block-based randomness and distributes the prize.
- **emergency-refund**: Refunds a specific participant's entry fee (owner-only).
- **emergency-withdraw**: Withdraws the contract's entire balance (owner-only).

#### Read-Only Functions
- **get-game-info**: Returns current game state.
- **get-round-info**: Retrieves details of a specific round.
- **get-participant-info**: Gets participant details for a round.
- **get-current-participants-count**: Returns the number of participants in the current round.
- **get-participant-by-index**: Retrieves a participant by their index in a round.

#### Private Functions
- **increment-participants-count**: Updates participant count for a round.
- **add-to-prize**: Adds to the prize pool for a round.

## Usage

### Starting a New Game
The contract owner starts a new game by calling `start-new-game` with the desired entry fee and maximum participants.

```clarity
(start-new-game u1000000 u100) ;; 1 STX entry fee, 100 max participants
```

### Joining the Draw
Users join the current round by calling `join-draw` and transferring the entry fee in STX.

```clarity
(join-draw)
```

### Drawing a Winner
Once the maximum participants are reached or the game is ended early, the `draw-winner` function selects a winner using block-based randomness and distributes the prize (95% to the winner, 5% to the contract owner).

```clarity
(draw-winner)
```

### Emergency Functions
- **Refund a Participant**: The owner can refund a participant's entry fee in emergencies.
  ```clarity
  (emergency-refund <participant-principal>)
  ```
- **Withdraw Contract Balance**: The owner can withdraw the contract's balance in emergencies.
  ```clarity
  (emergency-withdraw)
  ```

## Error Codes
| Code | Description |
|------|-------------|
| **u100** | Not authorized (only contract owner can perform action). |
| **u101** | Game is already active. |
| **u102** | Game is not active. |
| **u103** | Insufficient payment for entry fee. |
| **u104** | No participants in the round. |
| **u105** | Winner already drawn. |
| **u106** | Invalid block height for drawing. |
| **u107** | Participant already joined the round. |

## Security Considerations
- **Randomness**: The contract uses a simple block-based randomness mechanism. For higher security, consider more sophisticated randomness sources if available on Stacks.
- **Access Control**: Only the contract owner can start/end games, issue refunds, or withdraw funds.
- **Emergency Functions**: Use emergency functions cautiously to avoid disrupting active games.
- **Prize Distribution**: Ensures fair distribution with a fixed 5% commission to the owner.
## Contract Details
Address: STBBPJV84VWWJD1N2ZG0PC8EK6KBVWRR1J56CHHT.lucky-draw
## License
**MIT License**. See [LICENSE](LICENSE) for details.
<img width="1336" height="594" alt="image" src="https://github.com/user-attachments/assets/886b0990-f641-40b4-8b9f-828e9c2de189" />
