# 🎰 StacksLuck - Decentralized Lottery Protocol

**StacksLuck** is a fully decentralized lottery system built on the Stacks blockchain that ensures fairness, transparency, and trustless operation. Players can participate in lottery rounds, with automated winner selection and prize distribution.

## 🌟 Features

- **Transparent & Fair**: All lottery operations are on-chain and verifiable
- **Multiple Winners**: Support for multiple champions per round
- **Flexible Configuration**: Customizable entry fees, duration, and commission rates  
- **Refund Window**: Early withdrawal option for participants
- **Game History**: Complete historical data of all lottery rounds
- **Commission Control**: Admin fee capped at maximum 20%
- **Automated Payouts**: Smart contract handles prize distribution

## 🚀 Getting Started

### Prerequisites
- Stacks wallet (Hiro Wallet recommended)
- STX tokens for participation
- Basic understanding of Stacks blockchain

### Contract Deployment
```bash
# Deploy the contract to Stacks testnet/mainnet
clarinet deploy --network=testnet
```

## 📋 Core Functions

### Admin Functions
- `initialize-new-game` - Start a new lottery round
- `finalize-current-game` - End the current lottery and calculate prizes
- `choose-game-champions` - Select winners using verifiable randomness

### Player Functions  
- `buy-game-entry` - Purchase lottery tickets
- `request-entry-refund` - Withdraw tickets during refund period
- `claim-champion-prize` - Claim winnings if selected as champion

### Query Functions
- `get-prize-pool` - View current jackpot amount
- `get-user-entries` - Check your ticket count
- `is-game-active` - Check if lottery is running
- `get-game-history` - View past lottery results

## 🎮 How to Play

1. **Wait for Active Game**: Check if a lottery round is currently running
2. **Buy Entries**: Purchase lottery tickets using `buy-game-entry`
3. **Wait for Results**: Lottery ends automatically at the deadline block
4. **Check Winners**: View selected champions after admin finalizes the game
5. **Claim Prizes**: Winners can claim their share of the prize pool

## 💰 Economics

- **Entry Fee**: Configurable per game (default: 1 STX)
- **Prize Distribution**: Total pool minus admin commission, split among winners
- **Admin Commission**: 5% default, maximum 20%
- **Refund Period**: Early withdrawal window before lottery ends

## 🔒 Security Features

- **Owner-Only Admin Functions**: Critical operations restricted to contract deployer
- **Balance Validation**: Ensures users have sufficient STX before purchases
- **Deadline Enforcement**: Strict timing controls for game phases
- **Duplicate Winner Prevention**: Robust champion selection algorithm
- **Refund Protection**: Time-limited withdrawal mechanism

## 📊 Game Statistics

Each completed lottery round stores comprehensive data:
- Total number of entries
- Final prize pool amount  
- Number of champions selected
- Historical round tracking

## 🛠️ Technical Details

### Built With
- **Language**: Clarity (Stacks smart contract language)
- **Blockchain**: Stacks (Bitcoin layer-2)
- **Token Standard**: STX native token

### Contract Architecture
- **Data Variables**: Game state management
- **Maps**: Participant tracking and winner registry
- **Constants**: Error codes and configuration limits
- **Private Functions**: Internal logic and validations

## 🤝 Contributing

We welcome contributions to StacksLuck! Please feel free to submit issues, feature requests, or pull requests.

### Development Setup
```bash
# Clone the repository
git clone https://github.com/soomma/stacksluck

# Install Clarinet
curl -L https://github.com/hirosystems/clarinet/releases/download/v1.0.0/clarinet-linux-x64.tar.gz | tar xz

# Run tests
clarinet test
```

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚠️ Disclaimer

StacksLuck is experimental software. Participate at your own risk. Always verify contract code and understand the risks before interacting with smart contracts.

