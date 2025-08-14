// deploy.js — UUPS proxy deploy for ContributionNFTUpgradeable
// Reads config from .env (see .env.sample)

const { ethers, upgrades } = require("hardhat");

async function main() {
  // ---- env / defaults ----
  const NAME   = process.env.NFT_NAME   || "ArcVault Contribution NFT";
  const SYMBOL = process.env.NFT_SYMBOL || "ARCV";
  const BASE   = process.env.BASE_URI   || "ipfs://";
  const ROYALTY_RECEIVER = process.env.ROYALTY_RECEIVER || ethers.ZeroAddress;
  // 500 = 5.00% (in basis points, as OZ expects feeNumerator out of 10000)
  const ROYALTY_FEE = process.env.ROYALTY_FEE ? Number(process.env.ROYALTY_FEE) : 500;
  const ADMIN = process.env.ADMIN || (await ethers.getSigners())[0].address;

  console.log("Deploy config:");
  console.log({ NAME, SYMBOL, BASE_URI: BASE, ROYALTY_RECEIVER, ROYALTY_FEE, ADMIN });

  // ---- deploy ----
  const Contract = await ethers.getContractFactory("ContributionNFTUpgradeable");
  const proxy = await upgrades.deployProxy(
    Contract,
    [NAME, SYMBOL, BASE, ROYALTY_RECEIVER, ROYALTY_FEE, ADMIN],
    { kind: "uups" }
  );
  await proxy.waitForDeployment();

  const proxyAddr = await proxy.getAddress();
  console.log(`✅ Proxy deployed at: ${proxyAddr}`);

  // implementation (logic) address
  const implAddr = await upgrades.erc1967.getImplementationAddress(proxyAddr);
  console.log(`ℹ️  Implementation at: ${implAddr}`);

  // admin (for UUPS this is the proxy itself; upgrades guarded by _authorizeUpgrade)
  const adminSlot = await upgrades.erc1967.getAdminAddress(proxyAddr);
  console.log(`ℹ️  Proxy admin address (ERC1967 slot): ${adminSlot}`);

  console.log("\nNext:");
  console.log(`npx hardhat run scripts/print-impl.js --network ${hre.network.name} ${proxyAddr}`);
  console.log(`npx hardhat run scripts/verify-impl.js --network ${hre.network.name} ${proxyAddr}`);
}

main().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});
