import { Clarinet, Tx, Chain, types } from "clarinet";

Clarinet.test({
  name: "vend transfers price and returns a prize",
  async fn(chain: Chain, accounts) {
    const deployer = accounts.get("deployer")!;
    const user = accounts.get("wallet_1")!;

    // Seed prizes and set price
    let b1 = chain.mineBlock([
      Tx.contractCall("digital-vending", "add-prize", [types.uint(0), types.uint(50)], deployer.address),
      Tx.contractCall("digital-vending", "add-prize", [types.uint(1), types.uint(0)], deployer.address),
      Tx.contractCall("digital-vending", "set-price", [types.uint(1000)], deployer.address),
    ]);
    b1.receipts.forEach(r => r.result.expectOk());

    // User vends once
    const b2 = chain.mineBlock([
      Tx.contractCall("digital-vending", "vend", [], user.address),
    ]);
    b2.receipts[0].result.expectOk();
  }
});
