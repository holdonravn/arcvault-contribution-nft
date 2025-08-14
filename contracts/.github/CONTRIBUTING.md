# Contributing Guide

We welcome contributions from everyone!

Please follow these steps to set up your local environment and submit changes.

---

## 📦 Prerequisites

- Node.js >= 18.x
- npm or yarn
- Hardhat
- Git
- An Ethereum wallet (MetaMask recommended)
- Testnet ETH (Sepolia preferred)

---

## ⚙️ How to Run Locally / Testnet

1. **Clone the repository**
```bash
git clone https://github.com/holdonravn/<repo-name>.git
cd <repo-name>

2. **Install dependencies**
```bash
npm install
# or
yarn install
```

3. **Configure Environment Variables**
- Create a `.env` file in the project root.
- Use `.env.sample` as a reference:
```
RPC_URL=your_sepolia_rpc_url
PRIVATE_KEY=your_testnet_private_key
ETHERSCAN_API_KEY=your_etherscan_key # optional
```
- **Never commit private keys or sensitive data.**

4. **Run tests and local node**
```bash
npx hardhat test
npm run lint
```
*(Optional) Start local node:*
```bash
npx hardhat node
```

5. **Deploy to testnet**
```bash
npx hardhat run scripts/deploy.js --network sepolia
```
*(Upgrade or verify with similar commands.)*

---

## 🔀 Branch & PR Process

- Create a new branch for each feature or fix:
```bash
git checkout -b feat/short-description
git checkout -b fix/issue-id-description
```
- When ready:
```bash
git push origin [branch-name]
```
- Open a Pull Request on GitHub, describe the changes, include tests, and explain the motivation.

---

## ✅ Tests & Code Standards

- Add unit tests for all major functionality (90%+ coverage recommended).
- Ensure lint and tests pass before PR.
- Follow Prettier, ESLint, or the project’s style guide.

---

## 🔒 Security & Disclosures

- **Never** commit private keys, mnemonics, or API keys.
- Report vulnerabilities directly to maintainers or via SECURITY.md.

---

## 🙋‍♂️ Help & Discussion Channels

- Discussions/Telegram/Discord (**add relevant links**)
- “good first issue” and “help wanted” labels are good starting points

---

Thanks for contributing! 🚀
```

---

Bu dosyayı .github/CONTRIBUTING.md olarak eklemen projenin nasıl geliştirmen gereken var mı ve ekleyelim github a 
