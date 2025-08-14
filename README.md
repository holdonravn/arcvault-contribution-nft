<p align="center">
  <b>ArcVault Contribution NFT — Pre-launch / Testnet Only</b><br>
  <sub>Security hardening in progress. Contracts and roles are not final.</sub>
</p>

---

**Status:** Pre-launch (Testnet only)  
**Privileged roles:** SIGNER_ROLE / POLICY_ADMIN / METADATA_ADMIN / UPGRADER_ROLE → **TBD (to be assigned via multisig + timelock before mainnet)**

> ⚠️ Do not use on mainnet. No private keys, seeds, or API keys should ever be committed to this repository.


# ArcVault Contribution NFT — v1.0.4

**ArcVault Contribution NFT** — A secure, flexible, and fully upgradeable NFT infrastructure for provably representing on-chain contributions.  
Contributions are recorded with verified data and EIP-712 signatures, can be updated, permanently frozen, or converted into a **Soulbound** (non-transferable) identity badge.

---

## 🚀 Key Features

### Contribution Recording Mechanism
- On-chain contribution records using EIP-712 signatures.
- Supports both EOAs and EIP-1271 (multisig / corporate) signatures.

### Reward System
- Contributions are represented as NFTs.
- Can be integrated with token rewards or other incentive mechanisms.

### Flexible NFT Infrastructure
- Fully ERC-721 compliant  
- ERC-2981 (royalty reporting)  
- ERC-4906 (metadata update signaling) — for indexer compatibility

### Advanced Security
- Role-based Access Control (POLICY_ADMIN, METADATA_ADMIN, SIGNER_ROLE)  
- Pausable (emergency stop)  
- UUPS Upgradeable (controlled upgrades)  
- Per-token freeze (permanent metadata lock)  
- Soulbound Mode (disable transfer/approvals)

### Full Transparency
- All contribution data (approver address, category, score, CID) is fully queryable on-chain.

### Policy Flexibility
- Dynamic role assignments
- Customizable signer sets
- Adaptable for DAOs, enterprises, or open-source communities

---

## 📌 Types of Contributions

### 🛠 Technical Contributions
- Writing and optimizing smart contracts
- Developing and deploying dApps
- Bug bounties and security patches
- Testnet / mainnet feature testing
- Protocol upgrades

### 🌐 Community Contributions
- Organizing events, workshops, and AMAs
- Creating educational content (technical or non-technical)
- Managing official community channels
- Translating documentation, moderation

### 📢 Outreach & Growth
- Producing videos, podcasts, infographics
- Running marketing campaigns
- Building integrations and partnerships
- Managing social media growth

### 🔍 Research & Development
- Conducting security audits
- Proposing governance improvements
- Designing ecosystem growth strategies
- Market analysis and user feedback reports

---

📊 Technical Specs Table
| Feature           | Supported | Description                       |
|-------------------|-----------|-----------------------------------|
| ERC-721           | ✅         | Fully compliant                   |
| ERC-2981          | ✅         | Royalty reporting                 |
| ERC-4906          | ✅         | Metadata update signaling         |
| EIP-712           | ✅         | Signed contribution & update      |
| Soulbound Mode    | ✅         | Transfer/approval disabled        |
| Freeze (Per Token)| ✅         | Permanent metadata lock           |
| UUPS Upgrade      | ✅         | Controlled upgrade                 |
| Pausable          | ✅         | Emergency stop                    |
| EIP-1271          | ✅         | Multisig / corporate signatures   |
| EAS Attestation   | Optional  | Off-chain verification bridge     |

---

## 🚀 Deployment / Roles (Placeholder)

> **Note:** These addresses are placeholders for pre-launch/testnet only. Replace with actual addresses before mainnet deployment.

| Role              | Address (Placeholder)       | Description |
|-------------------|-----------------------------|-------------|
| `SIGNER_ROLE`     | `0x0000000000000000000000000000000000000000` | Signs verified contributions (multisig recommended, no timelock). |
| `POLICY_ADMIN`    | `0x0000000000000000000000000000000000000000` | Controls pause/SBT toggle; assign to a multisig with timelock. |
| `METADATA_ADMIN`  | `0x0000000000000000000000000000000000000000` | Can update metadata before freeze; lower threshold multisig possible. |
| `UPGRADER_ROLE`   | `0x0000000000000000000000000000000000000000` | Controls contract upgrades; separate from policy admin. |

📌 **Security Tip:** Use Gnosis Safe for each role with different member sets, and apply `TimelockController` (24–48h) for POLICY_ADMIN and UPGRADER_ROLE.

---
Governance & Roles
## Deployment

### Testnet Setup
1. Deploy contracts to {testnet name}.
2. Assign roles using the addresses below (placeholders for testnet use only).

### Roles (placeholders)

> **Note:** These addresses are placeholders for testnet.  
> Final mainnet roles will be assigned via multisig + timelock before launch.

- `DEFAULT_ADMIN_ROLE`: `0x0000000000000000000000000000000000000000` (TBD)
- `SIGNER_ROLE`: `0x0000000000000000000000000000000000000000` (TBD)
- `POLICY_ADMIN`: `0x0000000000000000000000000000000000000000` (TBD)
- `METADATA_ADMIN`: `0x0000000000000000000000000000000000000000` (TBD)
- `UPGRADER_ROLE`: `0x0000000000000000000000000000000000000000` (TBD)
- ## CI / Security
- Every PR runs tests, coverage and Slither static analysis (see `.github/workflows/ci.yml`).
- No secrets in repo: use `.env` (testnet only). See `SECURITY.md` for disclosure policy.

## Examples
- EIP-712 signing snippets in `examples/`:
  - `sign-mint.ts` → produce `signature` + payload for `mintWithSig`
  - `sign-update.ts` → produce `signature` + payload for `updateWithSig`
 
  - ## 🤝 Contributing

We welcome contributions from everyone!  
Please read our [Contributing Guide](.github/CONTRIBUTING.md) before making a pull request.
