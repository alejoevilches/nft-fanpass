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
    uint256 eventsCount;
    mapping(uint256 => bool) attendedEvents;
}

struct Event {
    STATUS status;
    uint256 requiredEventId;
    uint256 eventsAttendedToBuy;
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
    error BuyTicket_InvalidTier();
    error BuyTicket_NoTicketsAvailable();
    error BuyTicket_NotEnoughEth();
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
        uint256 eventsAttendedToBuy
    ) external view onlyOwner {
        idToEvent[eventId].status == STATUS.ACTIVE;
        idToEvent[eventId].requiredEventId == requiredEventId;
        idToEvent[eventId].eventsAttendedToBuy == eventsAttendedToBuy;
    }

    function createTier(uint256 eventId, Tier memory tier) internal onlyOwner {
        uint256 count = idToEvent[eventId].tierCount;
        idToEvent[eventId].tierCountToTier[count] = tier;
        idToEvent[eventId].tierCount++;
    }

    function buyTickets(
        uint256 eventId,
        uint256 amount,
        uint256 tier
    ) public payable {
        if (balanceOf(msg.sender) < 0) revert BuyTicket_NoFanPass();
        uint256 assistanceFilter = idToEvent[eventId].eventsAttendedToBuy;
        if (addressToFanPass[msg.sender].eventsCount < assistanceFilter)
            revert BuyTicket_NotAuthorized();
        if (tier >= idToEvent[eventId].tierCount)
            revert BuyTicket_InvalidTier();
        if (idToEvent[eventId].tierCountToTier[tier].amount < amount)
            revert BuyTicket_NoTicketsAvailable();
        uint256 amountRequired = idToEvent[eventId]
            .tierCountToTier[tier]
            .price * amount;
        if (msg.value < amountRequired) revert BuyTicket_NotEnoughEth();
        addressToFanPass[msg.sender].eventsCount++;
        addressToFanPass[msg.sender].attendedEvents[eventId] = true;
        idToEvent[eventId].tierCountToTier[tier].amount =
            idToEvent[eventId].tierCountToTier[tier].amount -
            amount;
    }
}
