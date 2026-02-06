// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

enum STATUS {
    ACTIVE,
    CANCELLED,
    FINALIZED
}

struct Tier {
    string name;
    uint256 price;
    uint256 amount;
}

struct Pass {
    uint256 eventsAttended;
    mapping(uint256 => bool) attendedEvents;
}

struct Event {
    STATUS status;
    uint256 requiredEventId;
    uint256 eventAttendedToBuy;
    uint256 tierCount;
    mapping(uint256 => Tier) tierCountToTier;
}

contract FanPass is ERC721 {
    uint256 passCount;
    address payable public owner;
    mapping(address => Pass) addressToFanPass;
    mapping(uint256 => Event) idToEvent;

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    error MintFanPass_PassAlreadyMinted();
    error BuyTicket_NoFanPass();
    error BuyTicket_NotAuthorized();
    error OnlyOwner();

    constructor() ERC721("FanPass", "FNP") {
        owner = payable(msg.sender);
    }

    function mintFanPass() public {
        if (balanceOf(msg.sender) > 0) revert MintFanPass_PassAlreadyMinted();
        _safeMint(msg.sender, passCount);
        passCount++;
    }

    function createEvent(
        uint256 eventId,
        uint256 requiredEventId,
        uint256 eventAttendedToBuy
    ) external view onlyOwner {
        idToEvent[eventId].status == STATUS.ACTIVE;
        idToEvent[eventId].requiredEventId == requiredEventId;
        idToEvent[eventId].eventAttendedToBuy == eventAttendedToBuy;
    }

    function createTier(uint256 eventId, Tier memory tier) internal onlyOwner {
        uint256 count = idToEvent[eventId].tierCount;
        idToEvent[eventId].tierCountToTier[count] = tier;
        idToEvent[eventId].tierCount++;
    }
}
