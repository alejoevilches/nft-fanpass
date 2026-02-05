// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

struct Pass {
    uint256 eventsAttended;
    mapping(uint256 => bool) attendedEvents;
}

contract FanPass is ERC721 {
    mapping(address => Pass) addressToFanPass;
    uint256 passCount;

    error MintFanPass_PassAlreadyMinted();
    error BuyTicket_NoFanPass();
    error BuyTicket_NotAuthorized();

    constructor() ERC721("FanPass", "FNP") {}

    function mintFanPass() public {
        if (balanceOf(msg.sender) > 0) revert MintFanPass_PassAlreadyMinted();
        _safeMint(msg.sender, passCount);
        passCount++;
    }

    function buyTicket(uint256 eventId, uint256 eventsAttendedToBuy) external {
        if (balanceOf(msg.sender) < 0) revert BuyTicket_NoFanPass();
        if (addressToFanPass[msg.sender].eventsAttended < eventsAttendedToBuy)
            revert BuyTicket_NotAuthorized();
        addressToFanPass[msg.sender].eventsAttended++;
        addressToFanPass[msg.sender].attendedEvents[eventId] = true;
    }
}
