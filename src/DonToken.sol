// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DonToken is ERC20 {
    uint256 constant public FAUCET_MINTING_AMOUNT = 100_000_000_000;
    mapping(address => bool) public userHasMinted;

    event UserMinted(address indexed user, uint256 amount);

    error UserHasMinted();

    constructor() ERC20("Donad", "DON") {}

    /**
     * @dev Returns decimal, 6 digit
     */
    function decimals() public pure override returns (uint8) {
        return 6;
    }

    /**
     * @dev for public minting, open for anyone
     */
    function faucetMinting() external {
        if (userHasMinted[msg.sender]) {
            revert UserHasMinted();
        }

        userHasMinted[msg.sender] = true;

        _mint(msg.sender, FAUCET_MINTING_AMOUNT);
        emit UserMinted(msg.sender, FAUCET_MINTING_AMOUNT);
    }

}