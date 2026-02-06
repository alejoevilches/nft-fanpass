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

struct Ticket {
    uint256 timestamp;
    uint256 amount;
    Tier tier;
    uint256 pricePaid;
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
    uint256 ticketCount;
    address payable public owner;
    mapping(address => Pass) addressToFanPass;
    mapping(uint256 => Event) idToEvent;
    mapping(address => uint256[]) ownerToTickets;
    mapping(uint256 => Ticket) ticketIdToTicket;

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    error MintFanPass_PassAlreadyMinted();
    error BuyTicket_NoFanPass();
    error BuyTicket_NotAuthorized();
    error BuyTicket_InvalidTier();
    error BuyTicket_NoTicketsAvailable();
    error BuyTicket_NotExactAmount();
    error BuyTicket_EventUnavailable();
    error BuyTicket_InvalidAmount();
    error OnlyOwner();

    event TicketEmited(uint256 eventId, address buyer);

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
    ) external onlyOwner {
        Event storage eventData = idToEvent[eventId];
        eventData.status = STATUS.ACTIVE;
        eventData.requiredEventId = requiredEventId;
        eventData.eventsAttendedToBuy = eventsAttendedToBuy;
    }

    function createTier(uint256 eventId, Tier memory tier) external onlyOwner {
        Event storage eventData = idToEvent[eventId];
        uint256 count = eventData.tierCount;
        eventData.tierCountToTier[count] = tier;
        eventData.tierCount++;
    }

    function buyTickets(
        uint256 eventId,
        uint256 amount,
        uint256 tier
    ) public payable {
        Event storage eventData = idToEvent[eventId];
        Pass storage fanPass = addressToFanPass[msg.sender];
        Tier storage tierData = eventData.tierCountToTier[tier];
        Ticket storage ticketInfo = ticketIdToTicket[ticketCount];

        if (amount <= 0) revert BuyTicket_InvalidAmount();
        if (eventData.status != STATUS.ACTIVE)
            revert BuyTicket_EventUnavailable();
        if (balanceOf(msg.sender) == 0) revert BuyTicket_NoFanPass();
        if (fanPass.eventsCount < eventData.eventsAttendedToBuy)
            revert BuyTicket_NotAuthorized();
        if (tier >= eventData.tierCount) revert BuyTicket_InvalidTier();
        if (tierData.amount < amount) revert BuyTicket_NoTicketsAvailable();
        uint256 amountRequired = tierData.price * amount;
        if (msg.value != amountRequired) revert BuyTicket_NotExactAmount();
        tierData.amount = tierData.amount - amount;
        if (!fanPass.attendedEvents[eventId]) {
            fanPass.eventsCount++;
            fanPass.attendedEvents[eventId] = true;
        }
        ticketInfo.amount = ticketInfo.amount;
        ticketInfo.pricePaid = amountRequired;
        ticketInfo.timestamp = block.timestamp;
        ticketInfo.tier = tierData;
        ownerToTickets[msg.sender].push(ticketCount);
        ticketCount++;
        emit TicketEmited(eventId, msg.sender);
    }

    function transferTicket(address to) external {}
}
