# ArcVault Contribution NFT (ARCV-NFT)

Production-ready, upgradeable ERC-721 that turns ecosystem activity into **verifiable, on-chain reputation**.

- **Upgradeable (UUPS)** on OpenZeppelin
- **Role & policy based controls** (mint/pause/metadata/upgrade)
- **EIP-2981 royalties**, **EIP-712** (signed mint/update; optional)
- **Pausable + optional Soulbound gates**
- **ERC-4906** metadata update signals
- **IPFS/CID** friendly `tokenURI` building

---

## ✨ What this repo contains
- `contracts/ContributionNFTUpgradeable.sol` – core upgradeable ERC-721 contract
- (Optional) scripts for deployment/verification (Hardhat/Foundry to be added)

---

## 🧱 Features (quick)
- **UUPS Upgradeable**: safe storage gap, `_authorizeUpgrade` gated by role
- **Governance-grade roles**: `POLICY_ADMIN`, `METADATA_ADMIN`, `SIGNER_ROLE`
- **Mint/Update with Sig (EIP-712)**: replay-safe using nonces & deadline
- **Soulbound mode**: blocks transfers/approvals when enabled
- **Royalty admin**: `setDefaultRoyalty / deleteDefaultRoyalty`
- **Events for indexers**: `ContributionMinted/Updated`, `MetadataUpdate`

---

## 🚀 Deploy (Remix quickstart)
1. **Compiler**: `0.8.20+`, **Optimizer ON**, Runs `600`.
2. Contract: `ContributionNFTUpgradeable`  
3. Click **Deploy with Proxy (UUPS)** (via OpenZeppelin plugin or factory)  
4. Call `initialize(name, symbol, baseURI, royaltyReceiver, royaltyFee, admin)`
5. (Öneri) Rollerini **timelock/Gnosis Safe**’e devret, deployer `renounceRole`.

> Not using Remix? Add Hardhat later with OZ upgrades plugin.

---

## 🔗 Integrations
- **Storage**: IPFS/CID or any gateway
- **Marketplaces**: EIP-2981 compatible
- **Identity**: optional EAS/attestation layer can be added

---

## 🧪 Test ideas
- Role gates (mint/pause/metadata/upgrade)
- EIP-712 digest/nonce/deadline + 1271 contract sig
- Pause + soulbound transfer/approve blocks
- ERC-4906 events fire on mint/update/freeze

---

## 📄 License
MIT

---

## 📬 Pointers
- **Contract path**: `contracts/ContributionNFTUpgradeable.sol`
- **Network**: _(fill after deploy)_
- **Proxy**: _(address)_, **Impl**: _(address)_
- **IPFS CID**: _(cid)_

> PR’lar, issue’lar ve öneriler hoş geldiniz.  
> _“Reputation is the new currency of trust — let’s make it verifiable.”_
