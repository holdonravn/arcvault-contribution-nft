// print-impl.js — prints the implementation address for a given proxy
// Usage: npx hardhat run scripts/print-impl.js --network <net> <proxyAddress>

const { upgrades } = require("hardhat");

async function main() {
  const proxy = process.argv[2];
  if (!proxy) {
    throw new Error("Usage: node scripts/print-impl.js <proxyAddress>");
  }
  const impl = await upgrades.erc1967.getImplementationAddress(proxy);
  const admin = await upgrades.erc1967.getAdminAddress(proxy);
  console.log(`Proxy:          ${proxy}`);
  console.log(`Implementation:  ${impl}`);
  console.log(`Admin (slot):    ${admin}`);
}

main().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});
