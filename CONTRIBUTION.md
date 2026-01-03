ArcVault Contribution Guide

Contributor: AidenRavn
Project: ArcVault Contribution NFT (Testnet Only, v1.0.4)

⸻

🎯 Purpose

ArcVault rewards meaningful contributions—on-chain or off-chain—by issuing verifiable, upgradeable NFTs. This guide explains how contributors like you can participate, record contributions, and ensure proper attribution.

⸻

📝 Contribution Types

1. Technical Contributions 🛠
	•	Smart contract development & testing
	•	Bug reports, patches, or audits
	•	dApp deployment & integration
	•	Protocol upgrades & optimization
	•	Testnet feedback

2. Community Contributions 🌐
	•	Organizing events, hackathons, AMAs
	•	Writing tutorials, guides, or documentation
	•	Community management and moderation
	•	Localization / translation

3. Outreach & Growth 📢
	•	Marketing campaigns & promotion
	•	Partnerships and integrations
	•	Social media engagement
	•	Content creation (videos, podcasts, graphics)

4. Research & Development 🔍
	•	Security audits and reports
	•	Governance proposals
	•	Ecosystem strategy design
	•	Market and user research

⸻

🔗 Contribution Process
	1.	Record your contribution:
	•	Use the EIP-712 signed payload (examples/sign-mint.ts) to submit your contribution on-chain.
	•	For off-chain contributions, submit supporting documentation or links to CONTRIBUTION.md.
	2.	Submit for verification:
	•	Contributions must be approved by a holder of SIGNER_ROLE.
	•	Provide category, description, score (policy-defined), and relevant links or proofs.
	3.	Mint your NFT badge:
	•	Upon approval, your contribution is represented as a Soulbound NFT.
	•	Metadata can be updated until frozen by METADATA_ADMIN.
	4.	Track & showcase:
	•	All minted NFTs are queryable on-chain.
	•	Share your ArcVault Contribution NFT across platforms as proof of participation.

⸻

📦 File Structure
	•	examples/ → Example scripts for EIP-712 signing & NFT minting
	•	contracts/ → Smart contracts (ERC-721, ERC-2981, ERC-4906)
	•	.github/CONTRIBUTING.md → PR & community contribution guidelines
	•	CONTRIBUTION.md → Your personal contribution record (this file)

⸻

🛡 Guidelines for Contributors
	•	Testnet only: Do not use private keys or mainnet funds.
	•	Document clearly: Provide enough context for approval & scoring.
	•	Respect roles: Only authorized signers can approve minting.
	•	Security first: Avoid committing secrets; use .env for test payloads.

⸻

🧾 Sample Contribution Entry

### Contributor: AidenRavn
**Date:** 2026-01-04
**Category:** Technical Contribution
**Description:** Implemented EIP-712 signature verification for mintWithSig payload.
**Scope:** Smart contract / NFT infrastructure
**Proof / Link:** https://github.com/ArcVault/testnet-examples/sign-mint.ts
**Status:** Approved / Pending


⸻

🤝 Contributing Code & Feedback
	1.	Fork the repository.
	2.	Create a branch: feature/<your-feature> or fix/<your-bug>.
	3.	Make changes & add tests/examples.
	4.	Submit a PR referencing your CONTRIBUTION.md entry.
	5.	Await verification by SIGNER_ROLE.

⸻

⚠️ Disclaimer

This contribution guide is for Testnet-only, research & educational purposes. By contributing:
	•	You acknowledge contributions are voluntary.
	•	NFTs minted are not financial instruments.
	•	ArcVault assumes no responsibility for misuse or deployment.

⸻

AidenRavn’s ArcVault Contribution Record is now ready to be used to log testnet contributions, track NFTs, and ensure proper recognition.
