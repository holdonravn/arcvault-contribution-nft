# 🛡️ Security Policy — ArcVault Contribution NFT (v1.0.4 – Testnet Only)

![Status](https://img.shields.io/badge/status-Testnet_Only-orange)
![License](https://img.shields.io/badge/license-MIT-green)
![Security](https://img.shields.io/badge/security-Hardening_in_progress-red)

> ⚠️ This repository is intended for **testnet and pre-launch use only**.  
> Contracts, roles, and addresses are not final and will be updated before mainnet deployment.

---

## 📌 Reporting a Vulnerability

If you believe you have found a vulnerability in this project:

1. **Do NOT** open a public GitHub issue for critical or sensitive bugs.
2. Instead, contact us privately via email:  
   ✉️ **[tayfunmalatyali@gmail.com](mailto:tayfunmalatyali@gmail.com)**
3. Alternatively, for low-severity issues, you may open a GitHub issue using the **"Security"** label.
4. Please use responsible disclosure. Do not share details publicly until the issue has been confirmed and patched.
5. **PGP encryption support is coming soon.**

---

## 🕒 Response Targets

| Action             | Timeframe       |
|--------------------|-----------------|
| 🔔 Acknowledge Bug | Within 72 hours |
| 🔧 Critical Patch  | Within 14 days  |

---

## 📂 Scope of Policy

This policy covers:

- ✅ Smart contracts in the `contracts/` directory
- ✅ Hardhat configurations used for deployment
- ✅ Testnet-specific security assumptions

❌ Out of Scope:

- ❌ Front-end apps (React, Next.js, etc.)
- ❌ Off-chain services (relayers, bots, APIs)
- ❌ 3rd-party infra (RPC, indexers, Graph, explorers)

---

## 🎁 Bounty Policy

| Stage        | Reward Model                         |
|--------------|---------------------------------------|
| 🔧 Testnet    | Community recognition (best effort)  |
| 🚀 Mainnet    | Full bug bounty program (TBD)        |

---

## 🚫 Known Non-Issues

- Testnet contracts may be upgraded or redeployed at any time.
- Roles and multisigs are **placeholders** during testnet.
- Metadata and contract structure may change before launch.

---

## 🏛 Governance & Upgrade Policy

- Mainnet contracts will use **Gnosis Safe** with **TimelockController (24–48h)**.
- All privileged roles (`SIGNER`, `UPGRADER`, `POLICY_ADMIN`, `METADATA_ADMIN`) will be assigned to multisigs.

---

## 🔒 User Security Tips

- Never share private keys, seed phrases, or access tokens.
- Only use contracts verified from the official GitHub and block explorer links.
- For multisig admins, use Gnosis Safe with appropriate threshold settings.
- Always verify that `.env` and `secrets` files are excluded from Git via `.gitignore`.

---

## 📬 Contact

📧 [tayfunmalatyali@gmail.com](mailto:tayfunmalatyali@gmail.com)  
🔒 PGP support: _Coming Soon_  
🌐 GitHub Issues: use the `Security` label for minor/public bugs.

---
