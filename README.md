<p align="center">
  <h1>ArcVault Contribution NFT <sub><code>v1.0.4 – Testnet Only</code></sub></h1>
  <i>Secure & Upgradeable NFT Infra for On-Chain Contribution Recognition</i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/status-Testnet_Only-orange">
  <img src="https://img.shields.io/badge/license-MIT-green">
  <img src="https://img.shields.io/badge/security-Hardening_in_progress-red">
</p>

> ⚠️ Do not use on mainnet. No private keys, seeds, or API keys should ever be committed to this repository.
<p align="center">
  <b>ArcVault Contribution NFT — Pre-launch / Testnet Only</b><br>
  <sub>Security hardening in progress. Contracts and roles are not final.</sub>
</p>

---

**Status:** Pre-launch (Testnet only)  
**Privileged roles:** SIGNER_ROLE / POLICY_ADMIN / METADATA_ADMIN / UPGRADER_ROLE → **TBD (to be assigned via multisig + timelock before mainnet)**

> ⚠️ Do not use on mainnet. No private keys, seeds, or API keys should ever be committed to this repository.


📍 Why / Use Case

### Why ArcVault Contribution NFT?
Traditional methods of recognizing open-source or community contributions—such as off-chain leaderboards, forum posts, or centralized badges—are non-verifiable, easily manipulated, and rarely portable across projects or ecosystems. ArcVault Contribution NFT solves this problem by turning every meaningful on-chain or off-chain contribution into a secure, upgradeable, and verifiable NFT badge backed by cryptographic proof.

With ArcVault, individual contributors, DAOs, enterprises, and developer communities can transparently track, verify, and reward all forms of contributions—code, security, research, community building, outreach—on any EVM-compatible chain.

---

### Use Cases

- **Open Source DAOs & Protocols:**  
Reward developers and active community members with non-transferable (Soulbound) NFTs that represent unique, verifiable contributions—such as deploying new features, fixing bugs, or auditing code.

- **Enterprise & Team Environments:**  
Issue digitally signed, immutable contribution records for employees or external collaborators, making performance reviews, bounties, and team reputation portable and tamper-proof.

- **Event and Community Recognition:**  
Distribute NFT-based badges for hackathon participation, event organization, public speaking, technical writing, or ambassador programs that remain provable and updatable over time.

- **Growth Campaigns & Ambassadorships:**  
Track marketing, outreach, or onboarding contributions—including content creation, social media activity, or partnership formation—each recorded and verified on-chain.

- **Reputation and Attestation:**  
Integrate with on-chain governance or attestation protocols to leverage verifiable contribution history for voting rights, incentives, or access control within DAOs.

---

**In summary:**  
ArcVault is the missing, secure, and upgradeable layer for turning any on-chain or off-chain contribution into a portable, provable achievement that strengthens your project’s transparency, reputation, and incentives.

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
 
  ---

## 🤝 Contributing

We welcome contributions from everyone — developers, researchers, designers, product managers, documentation writers, and ecosystem builders.

> 💡 **Important Note:**  
> There is currently **no guaranteed reward program** for contributors.  
> However, depending on the project's evolution and governance, **retroactive recognition or future contribution-based mechanisms may be introduced**.

Please read our [Contributing Guide](.github/CONTRIBUTING.md) before making a pull request.
