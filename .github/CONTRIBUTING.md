
# 🤝 Contributing to ArcVault

First of all, thank you for your interest in contributing!
ArcVault is a next-generation, early-stage infrastructure protocol focused on secure, upgradeable NFT-based contribution and recognition systems.

We welcome contributions from developers, researchers, designers, product managers, documentation writers, and ecosystem builders.

---

## 📦 Getting Started

1. **Fork the Repository**

Click “Fork” at the top right of the [main repo page] to create your own copy.

2. **Clone Your Fork**

```bash
git clone https://github.com/YOUR_USERNAME/arcvault-contribution-nft
cd arcvault-contribution-nft
```

3. **Install Dependencies**

```bash
yarn install
# or
npm install
```

4. **Set Up Environment Variables (Testnet Only)**

Copy the example file and provide your values:

```bash
cp .env.example .env
# Fill out RPC URLs, private keys for test wallets, etc.
```

---

## 🧰 Contribution Workflow

1. **Create a New Branch for Your Feature/Fix**

```bash
git checkout -b feat/short-description
```

2. **Make Your Changes**
- Follow coding standards (`solhint`, `eslint`, etc.).
- Add or update tests if necessary.
- Update documentation and comments with clear explanations.
- For UI/Docs: preview locally before submitting.

3. **Run Tests & Lint**

```bash
yarn test
yarn lint
# or
npm run test
npm run lint
```

4. **Commit Your Changes**

Use clear and descriptive commit messages:

```bash
git commit -m "feat(module): brief description of the change"
```

5. **Push and Open a Pull Request**

```bash
git push origin feat/short-description
# Then open a PR via GitHub UI
```

- Reference related issues if any (using `Closes #issue-number` in the PR body).
- Add a short summary, screenshots for UI, and test results if relevant.

---

## 📑 Guidelines & Standards

- **Coding Standards:**
All Solidity code must pass `solhint` checks; JS/TS must pass `eslint`.
- **Tests:**
Each significant feature/fix should be covered by unit tests. See `test/` folder for examples.
- **Documentation:**
Add or update docs for new features, APIs, configs, or usage.
- **Security Best Practices:**
Never commit secrets, mnemonics, or production keys.
See `SECURITY.md` for vulnerability disclosure guidelines.
- **Pull Requests:**
Follow our [PR template](.github/PULL_REQUEST_TEMPLATE.md).
- **Issues:**
Use the [issue template](.github/ISSUE_TEMPLATE.md) and search for duplicates before opening a new issue.
- **Respect:**
All contributors must follow the [Code of Conduct](CODE_OF_CONDUCT.md).

---

## 🏷️ Good First Issues

We regularly tag issues as [`good first issue`] for newcomers and [`help wanted`] for broader contributions.

---

## 🙏 Thank You

Every contribution counts—whether it’s code, suggestions, bug reports, tests, documentation, or design!
Help us build the future of provable, on-chain reputation and contribution together.
