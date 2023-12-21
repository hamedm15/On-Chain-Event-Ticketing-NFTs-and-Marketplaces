// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "../interfaces/ITicketNFT.sol";

contract TicketNFT is ITicketNFT {
    //ticket metadata
    struct Ticket {string holderName;bool used;uint256 eventExpiryDate;}
    address public primaryMarketAddress; 
    address public eventCreator;   //store address of the event creator
    string public eventName;  
    uint256 public eventExpiryDate; //expiry date for the entire event
    uint256 private nextticketID = 1;  
    uint256 public maxNumberOfTickets; 
    //mappings
    mapping(uint256 => Ticket) private tickets;//ticket Id to met data
    mapping(address => uint256) private balances;  
    mapping(uint256 => address) private ticketOwners; //ticketID to owner addresse
    mapping(uint256 => address) private ticketApprovals; //ticketID to approved addresse

    constructor(address _eventCreator, string memory _eventName, uint256 _maxNumberOfTickets) {
        eventCreator = _eventCreator;
        eventName = _eventName;
        maxNumberOfTickets = _maxNumberOfTickets;
        primaryMarketAddress = msg.sender;
        eventExpiryDate = block.timestamp + (10 * 86400); 
    }

    //no need for further implemenation it is in primary

    function mint(address holder, string memory holderName) external override returns (uint256) {
        require(msg.sender == primaryMarketAddress, "Only Primary Market can mint tickets");
        require(nextticketID <= maxNumberOfTickets, "Max ticket limit reached");
        require(block.timestamp <= eventExpiryDate, "Event has expired");

        uint256 ticketID = nextticketID++;
        tickets[ticketID] = Ticket(holderName, false, eventExpiryDate);
        ticketOwners[ticketID] = holder; 
        balances[holder]++;

        emit Transfer(address(0), holder, ticketID);
        return ticketID;
    }
    modifier ticketExists(uint256 ticketID) {require(ticketOwners[ticketID] != address(0) && ticketID < nextticketID, "Ticket does not exist");_;}

    function balanceOf(address holder) external view override returns (uint256) {return balances[holder];}
    function holderOf(uint256 ticketID) external view override ticketExists(ticketID) returns (address) {return ticketOwners[ticketID];}

    function transferFrom(address from, address to, uint256 ticketID) external override ticketExists(ticketID) {
        require(to != address(0), "Transfer to the zero/burn address");
        require(from != address(0), "Transfer from the zero/burn address");
        require(from == ticketOwners[ticketID], "Transfer from incorrect owner");
        require(from == msg.sender || ticketApprovals[ticketID] == msg.sender, "Caller is not owner nor approved");

        ticketOwners[ticketID] = to;
        balances[from]--;
        balances[to]++;
        ticketApprovals[ticketID] = address(0);

        emit Transfer(from, to, ticketID);
        emit Approval(from, address(0), ticketID);
    }

    function approve(address to, uint256 ticketID) external override ticketExists(ticketID) {
        require(ticketOwners[ticketID] == msg.sender, "Caller is not ticket owner");
        ticketApprovals[ticketID] = to;
        emit Approval(msg.sender, to, ticketID);
    }

    function getApproved(uint256 ticketID) external view override ticketExists(ticketID) returns (address){return ticketApprovals[ticketID];}

    function updateHolderName(uint256 ticketID, string calldata newName) external override ticketExists(ticketID){
        require(ticketOwners[ticketID] == msg.sender, "Only ticket holder can update name");
        tickets[ticketID].holderName = newName;
    }

    function setUsed(uint256 ticketID) external override ticketExists(ticketID) {
        require(msg.sender == eventCreator, "Only creator can set ticket as used");
        require(!tickets[ticketID].used, "Ticket already used");
        require(block.timestamp <= eventExpiryDate, "Event TicketNFT expired");
        tickets[ticketID].used = true;
    }

    function isExpiredOrUsed(uint256 ticketID) external view override ticketExists(ticketID) returns (bool) {return tickets[ticketID].used || block.timestamp > eventExpiryDate;}
    function creator() external view override returns (address) {return eventCreator;}
    function holderNameOf(uint256 ticketID) external view override ticketExists(ticketID) returns (string memory) {return tickets[ticketID].holderName;}

}
