// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "../interfaces/ISecondaryMarket.sol";
import "../interfaces/ITicketNFT.sol";
import "./PurchaseToken.sol";

contract SecondaryMarket is ISecondaryMarket {
    PurchaseToken private purchaseToken;

    struct Bid {address bidder; uint256 amount; string newName ;} //store bidderaddreess, amount of bid and new holder name if bid is accepted
    struct TicketListing {address seller; uint256 price; bool isActive;} //store seller address, listing price and whether the listing is "active", not been delisted
    mapping(address => mapping(uint256 => Bid)) private bids;
    mapping(address => mapping(uint256 => TicketListing)) private listings;

    constructor(PurchaseToken _purchaseToken) {
        purchaseToken = _purchaseToken;
    }

    modifier ticketExpiredOrUsed(address ticketCollection, uint256 ticketID) {
        require(!ITicketNFT(ticketCollection).isExpiredOrUsed(ticketID), "Ticket expired or used");_;}

    function listTicket(address ticketCollection, uint256 ticketID, uint256 price) external override ticketExpiredOrUsed(ticketCollection,ticketID){
        ITicketNFT(ticketCollection).transferFrom(msg.sender, address(this), ticketID);
        listings[ticketCollection][ticketID] = TicketListing(msg.sender, price, true);
        bids[ticketCollection][ticketID] = Bid(address(0), price, "");

        emit Listing(msg.sender, ticketCollection, ticketID, price);
    }

    function submitBid(address ticketCollection, uint256 ticketID, uint256 bidAmount, string calldata name) external override ticketExpiredOrUsed(ticketCollection,ticketID){
        TicketListing storage listing = listings[ticketCollection][ticketID];
        require(listing.isActive, "Ticket not for sale");
        require(bidAmount >= bids[ticketCollection][ticketID].amount, "Bid too low");
        require(listing.seller != msg.sender, "Seller cannot bid on his own listings");

        purchaseToken.transferFrom(msg.sender, address(this), bidAmount);

        //return purchase tokensto the previous highest bid leave no money "stuck" in the contract address
        Bid storage currentBid = bids[ticketCollection][ticketID];
        if (currentBid.bidder != address(0)){//0aaddress as "initial bidder" its the price set when listed
            require(bidAmount > bids[ticketCollection][ticketID].amount, "Bid too low");
            require(purchaseToken.transfer(currentBid.bidder, currentBid.amount), "Failed to refund previous bid");}

        //accept the new bid
        bids[ticketCollection][ticketID] = Bid(msg.sender, bidAmount, name);
        emit BidSubmitted(msg.sender, ticketCollection, ticketID, bidAmount, name);
    }

    function getHighestBid(address ticketCollection, uint256 ticketID) external view override returns (uint256) {return bids[ticketCollection][ticketID].amount;}
    function getHighestBidder(address ticketCollection, uint256 ticketID) external view override returns (address) {return bids[ticketCollection][ticketID].bidder;}

    function acceptBid(address ticketCollection, uint256 ticketID) external override ticketExpiredOrUsed(ticketCollection,ticketID){
        TicketListing storage listing = listings[ticketCollection][ticketID];
        Bid storage highestBid = bids[ticketCollection][ticketID];
        require(listing.isActive, "No active listing");
        require(listing.seller == msg.sender, "Not seller");
        require(highestBid.bidder != address(0), "No bids yet");
        ITicketNFT ticketNFT = ITicketNFT(ticketCollection);
        ticketNFT.updateHolderName(ticketID, highestBid.newName);
        ticketNFT.transferFrom(address(this), highestBid.bidder, ticketID);
        uint256 fee = (highestBid.amount * 0.05e18) / 1e18;
        purchaseToken.transfer(ticketNFT.creator(), fee);
        purchaseToken.transfer(listing.seller, highestBid.amount - fee);
        listings[ticketCollection][ticketID].isActive = false;
        delete bids[ticketCollection][ticketID];

        emit BidAccepted(highestBid.bidder, ticketCollection, ticketID, highestBid.amount, highestBid.newName);
    }

    function delistTicket(address ticketCollection, uint256 ticketID) external override {
        TicketListing storage listing = listings[ticketCollection][ticketID];
        require(listing.isActive, "No active listing");
        ITicketNFT ticketNFT = ITicketNFT(ticketCollection);
        if (!ticketNFT.isExpiredOrUsed(ticketID)){require(listing.seller == msg.sender, "Delister is not seller");}
        Bid storage highestBid = bids[ticketCollection][ticketID];
        if (highestBid.bidder != address(0)) {
            purchaseToken.transfer(highestBid.bidder, highestBid.amount);
        }
        ticketNFT.transferFrom(address(this), msg.sender, ticketID);
        listings[ticketCollection][ticketID].isActive = false;
        delete bids[ticketCollection][ticketID];

        emit Delisting(ticketCollection, ticketID);
    }
}

