// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "../interfaces/IPrimaryMarket.sol";
import "../interfaces/ITicketNFT.sol";
import "./TicketNFT.sol";
import "./PurchaseToken.sol";

contract PrimaryMarket is IPrimaryMarket {
    PurchaseToken private purchaseToken;

    ///map ticket collection addresses to their mint price.
    mapping(address => uint256) private mintPrice;

    constructor(PurchaseToken _purchaseToken) {purchaseToken = _purchaseToken;}

    function createNewEvent(string memory eventName,uint256 price,uint256 maxNumberOfTickets) external override 
    returns (ITicketNFT ticketCollection) {
        require(msg.sender != address(0), "Event creator cannot be the zero/burn address");
        require(bytes(eventName).length > 0, "Event name cannot be empty");
        require(maxNumberOfTickets > 0, "Maximum number of tickets must be positive");
        require(price > 0, "Price must be positive");

        TicketNFT newTicketNFT = new TicketNFT(msg.sender, eventName, maxNumberOfTickets);
        mintPrice[address(newTicketNFT)] = price;
        emit EventCreated(msg.sender, address(newTicketNFT), eventName, price, maxNumberOfTickets);
        return ITicketNFT(address(newTicketNFT));
    }

    function purchase(address ticketCollection,string memory holderName) external override returns (uint256 id) {
        ITicketNFT ticketNFT = ITicketNFT(ticketCollection);
        purchaseToken.transferFrom(msg.sender, ticketNFT.creator(), mintPrice[ticketCollection]);

        uint256 ticketID = ticketNFT.mint(msg.sender, holderName);
        emit Purchase(msg.sender, ticketCollection, ticketID, holderName);
        return ticketID;
    }


    function getPrice(address ticketCollection) external view override returns (uint256 price) {
        require(mintPrice[ticketCollection] > 0, "Ticket Collection Not Found");
        return mintPrice[ticketCollection];
    }

}