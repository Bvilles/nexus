# Nexus - Decentralized Social Media Platform

Nexus is a decentralized social media platform built on the Stacks blockchain that empowers users to truly own their content through NFTs and enables content monetization through micro-transactions.

## Features

- **Content Ownership**: All posts are minted as NFTs, giving users true ownership of their content
- **User Profiles**: Customizable profiles with usernames and bios
- **Content Monetization**: Built-in tipping system using STX tokens
- **Decentralized Storage**: Content stored on Gaia
- **Smart Contract Security**: Built with Clarity for maximum security and predictability

## Smart Contract Architecture

The platform consists of several key components:

### Data Structures
- `Users`: Stores user profiles and metadata
- `Posts`: Stores post content and associated metadata
- `UserPosts`: Maps users to their posts
- `content-nft`: NFT definition for content ownership

### Key Functions

#### User Management
- `register-user`: Create a new user profile
- `update-profile`: Update user profile information
- `get-user-profile`: Retrieve user profile data

#### Content Management
- `create-post`: Create a new post (mints NFT)
- `get-post`: Retrieve post details
- `get-user-posts`: Get all posts by a user

#### Monetization
- `tip-post`: Send STX tokens to content creators

## Getting Started

### Prerequisites
- Stacks wallet (Hiro Wallet recommended)
- STX tokens for transaction fees
- Node.js and NPM installed

### Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/nexus.git
cd nexus
```

2. Install dependencies
```bash
npm install
```

3. Configure environment variables
```bash
cp .env.example .env
# Edit .env with your configuration
```

### Deployment

1. Deploy the smart contract
```bash
clarinet contract deploy
```

2. Initialize the frontend
```bash
npm run dev
```


## Security Considerations

- All functions include appropriate checks and balances
- NFT minting is restricted to content creators
- Tipping system includes verification steps
- Profile updates are restricted to profile owners

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

