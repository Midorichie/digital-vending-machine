# Digital Vending Machine Smart Contract (Phase 2)

A Stacks blockchain smart contract that implements a digital vending machine dispensing fungible tokens (FT) and non-fungible tokens (NFT) as prizes. This enhanced version includes improved security, weighted prize selection, and comprehensive statistics tracking.

## Features

### Core Functionality
- **Prize Dispensing**: Dispenses both fungible tokens (PRIZE-TOKEN) and NFTs (PRIZE-NFT)
- **Configurable Pricing**: Admin can set STX price for vending
- **Pause/Resume**: Emergency pause functionality for maintenance
- **Weighted Prizes**: Each prize has a configurable weight affecting selection probability

### Enhanced Security Features
- **Improved Randomness**: Uses multiple block properties and user data for prize selection
- **Admin Controls**: Comprehensive admin functions with proper authorization
- **Input Validation**: Validates all user inputs and parameters
- **Error Handling**: Detailed error codes for different failure scenarios

### Statistics & Tracking
- **Vend History**: Complete history of all vending transactions
- **User Statistics**: Track individual user vending activity
- **Revenue Tracking**: Monitor total revenue and vending volume
- **Prize Analytics**: Weight-based prize distribution statistics

## Contract Structure

### Constants
- `KIND-FT` (0): Fungible token prize type
- `KIND-NFT` (1): Non-fungible token prize type
- Error codes: 100-107 for different failure scenarios

### Data Variables
- `admin`: Contract administrator
- `treasury`: Payment recipient address
- `price`: Cost per vend in micro-STX
- `paused`: Emergency pause state
- `prizes`: List of available prizes with weights
- `nft-next-id`: Next NFT token ID to mint

### Prize Configuration
Each prize is defined as:
```clarity
{
  kind: uint,    // KIND-FT or KIND-NFT
  amount: uint,  // FT amount or NFT metadata
  weight: uint   // Selection probability weight
}
```

## Usage

### For Users

#### Vending
```bash
# Check current price
(contract-call? .digital-vending get-price)

# Check available prizes
(contract-call? .digital-vending get-prizes)

# Purchase from vending machine
(contract-call? .digital-vending vend)

# Check your FT balance
(contract-call? .digital-vending get-ft-balance 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

#### Statistics
```bash
# View overall statistics
(contract-call? .digital-vending get-statistics)

# Check your vending history
(contract-call? .digital-vending get-user-vend-count 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

# View specific vend details
(contract-call? .digital-vending get-vend-history u1)
```

### For Administrators

#### Setup
```bash
# Set price (1 STX = 1,000,000 micro-STX)
(contract-call? .digital-vending set-price u1000000)

# Set treasury address
(contract-call? .digital-vending set-treasury 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)

# Mint FT tokens for prizes
(contract-call? .digital-vending admin-mint-ft u1000000)
```

#### Prize Management
```bash
# Add FT prize (100 tokens, weight 10)
(contract-call? .digital-vending add-prize u0 u100 u10)

# Add NFT prize (weight 5)
(contract-call? .digital-vending add-prize u1 u1 u5)

# Remove prize at index 0
(contract-call? .digital-vending remove-prize u0)

# Clear all prizes
(contract-call? .digital-vending clear-prizes)
```

#### Maintenance
```bash
# Pause the vending machine
(contract-call? .digital-vending pause true)

# Resume operations
(contract-call? .digital-vending pause false)

# Withdraw accumulated FT tokens
(contract-call? .digital-vending admin-withdraw-ft u1000 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)
```

## Phase 2 Improvements

### Bug Fixes
1. **Fixed Admin Authorization**: Corrected `only-admin` function to return proper response type
2. **Error Handling**: Improved error propagation using `try!` instead of `unwrap!`
3. **Input Validation**: Added comprehensive validation for all user inputs

### Security Enhancements
1. **Improved Randomness**: Enhanced random seed generation using multiple block properties
2. **Weighted Selection**: Replaced predictable modulo with weighted random selection
3. **Authorization Checks**: Strengthened admin function access control
4. **Balance Validation**: Added checks for sufficient token balances

### New Features
1. **Prize Weights**: Each prize can have different selection probabilities
2. **Statistics Tracking**: Comprehensive tracking of usage and revenue
3. **Vend History**: Complete audit trail of all transactions
4. **Individual Prize Removal**: Remove specific prizes without clearing all
5. **Token Management**: Admin functions for minting and withdrawing tokens
6. **User Analytics**: Track individual user activity

### Enhanced Error Handling
- `ERR-INSUFFICIENT-BALANCE`: Token balance too low
- `ERR-INVALID-AMOUNT`: Invalid amount parameters
- `ERR-PRIZE-NOT-FOUND`: Prize index doesn't exist
- `ERR-MAX-PRIZES-REACHED`: Prize list is full (20 max)

## Development

### Setup
```bash
# Install Clarinet
npm install -g @hirosystems/clarinet-cli

# Clone the project
git clone <repository-url>
cd digital-vending-machine

# Check syntax
clarinet check

# Run tests
clarinet test

# Start local devnet
clarinet devnet start
```

### Testing
```bash
# Test the contract
clarinet console

# In the console, test basic functionality:
(contract-call? .digital-vending get-price)
(contract-call? .digital-vending add-prize u0 u100 u10)
(contract-call? .digital-vending vend)
```

## Token Economics

### Prize Distribution
- **Weighted Selection**: Prizes with higher weights are more likely to be selected
- **Fair Distribution**: Random selection prevents gaming the system
- **Configurable Odds**: Admin can adjust prize weights to balance economy

### Revenue Model
- **Direct Payment**: Users pay STX directly for each vend
- **Treasury System**: All payments go to configurable treasury address
- **Transparent Tracking**: All revenue and statistics are publicly viewable

## Security Considerations

1. **Admin Keys**: Secure admin private keys as they control the entire system
2. **Treasury Security**: Use secure treasury addresses for payment collection
3. **Pause Mechanism**: Emergency pause available for security incidents
4. **Token Supply**: Monitor and manage FT token supply for prizes

## License

MIT License - see LICENSE file for details

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## Support

For questions or issues, please open an issue in the repository or contact the development team.
