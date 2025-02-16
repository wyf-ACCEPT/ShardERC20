import "dotenv/config"
import { deployContract, deployUpgradeableContract } from "./utils"

async function main() {
  await deployContract(
    "USDC", []
  )
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

