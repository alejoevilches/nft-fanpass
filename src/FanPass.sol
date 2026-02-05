// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

struct Pass {
    uint256 eventsAttended;
}

contract FanPass is ERC721 {
    mapping(address => Pass) addressToFanPass;
    uint256 passCount;

    error MintFanPass_PassAlreadyMinted();

    constructor() ERC721("FanPass", "FNP") {}

    function mintFanPass() public {
        if (balanceOf(msg.sender) > 0) revert MintFanPass_PassAlreadyMinted();
        _safeMint(msg.sender, passCount);
        passCount++;
    }
}
