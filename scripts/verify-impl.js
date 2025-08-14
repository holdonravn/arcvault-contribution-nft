// verify-impl.js — Etherscan verification for the implementation behind a proxy
// Usage: npx hardhat run scripts/verify-impl.js --network <net> <proxyAddress>

const hre = require("hardhat");
const { upgrades } = require("hardhat");

async function main() {
  const proxy = process.argv[2];
  if (!proxy) {
    throw new Error("Usage: node scripts/verify-impl.js <proxyAddress>");
  }

  const impl = await upgrades.erc1967.getImplementationAddress(proxy);
  console.log(`Implementation behind proxy ${proxy}: ${impl}`);

  // UUPS impls usually have no constructor args
  await hre.run("verify:verify", {
    address: impl,
    constructorArguments: [],
  });

  console.log("✅ Implementation verified on Etherscan.");
}

main().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});
