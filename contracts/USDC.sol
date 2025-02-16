// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDC is ERC20 {
    // ============================= Constants =============================
    // ============================= Parameters ============================
    // ============================== Storage ==============================
    // =============================== Events ==============================
    // ======================= Modifier & Constructor ======================
    constructor() ERC20("USD Circle", "USDC") {
        _mint(msg.sender, 1_000_000_000 * 10 ** decimals());
    }
    // =========================== View functions ==========================
    // ========================== Write functions ==========================
    // ====================== Write functions - admin ======================
}

