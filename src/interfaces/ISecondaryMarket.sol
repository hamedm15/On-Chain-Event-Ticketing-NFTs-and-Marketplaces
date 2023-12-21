// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

/**
 * @dev Required interface for the secondary market.
 * The secondary market is the point of sale for tickets after they have been initially purchased from the primary market
 */
interface ISecondaryMarket {
    /**
     * @dev Event emitted when a new ticket listing is created
     */
    event Listing(
        address indexed holder,
        address indexed ticketCollection,
        uint256 indexed ticketID,
        uint256 price
    );

    /**
     * @dev Event emitted when a bid has been submitted for the ticket
     */
    event BidSubmitted(
        address indexed bidder,
        address indexed ticketCollection,
        uint256 indexed ticketID,
        uint256 bidAmount,
        string newName
    );

    /**
     * @dev Event emitted when a bid has been submitted for the ticket
     */
    event BidAccepted(
        address indexed bidder,
        address indexed ticketCollection,
        uint256 indexed ticketID,
        uint256 bidAmount,
        string newName
    );

    /**
     * @dev Event emitted when a ticket is delisted
     */
    event Delisting(address indexed ticketCollection, uint256 indexed ticketID);

    /**
     * @dev This method lists a ticket with `ticketID` for sale by transferring the ticket
     * such that it is held by this contract. Only the current owner of a specific
     * ticket is able to list that ticket on the secondary market. The purchase
     * `price` is specified in an amount of `PurchaseToken`.
     * Note: Only non-expired and unused tickets can be listed
     */
    function listTicket(
        address ticketCollection,
        uint256 ticketID,
        uint256 price
    ) external;

    /** @notice This method allows the msg.sender to submit a bid for the ticket from `ticketCollection` with `ticketID`
     * The `bidAmount` should be kept in escrow by the contract until the bid is accepted, a higher bid is made,
     * or the ticket is delisted.
     * If this is not the first bid for this ticket, `bidAmount` must be strictly higher that the previous bid.
     * `name` gives the new name that should be stated on the ticket when it is purchased.
     * Note: Bid can only be made on non-expired and unused tickets
     */
    function submitBid(
        address ticketCollection,
        uint256 ticketID,
        uint256 bidAmount,
        string calldata name
    ) external;

    /**
     * Returns the current highest bid for the ticket from `ticketCollection` with `ticketID`
     */
    function getHighestBid(
        address ticketCollection,
        uint256 ticketId
    ) external view returns (uint256);

    /**
     * Returns the current highest bidder for the ticket from `ticketCollection` with `ticketID`
     */
    function getHighestBidder(
        address ticketCollection,
        uint256 ticketId
    ) external view returns (address);

    /*
     * @notice Allow the lister of the ticket from `ticketCollection` with `ticketID` to accept the current highest bid.
     * This function reverts if there is currently no bid.
     * Otherwise, it should accept the highest bid, transfer the money to the lister of the ticket,
     * and transfer the ticket to the highest bidder after having set the ticket holder name appropriately.
     * A fee charged when the bid is accepted. The fee is charged on the bid amount.
     * The final amount that the lister of the ticket receives is the price
     * minus the fee. The fee should go to the creator of the `ticketCollection`.
     */
    function acceptBid(address ticketCollection, uint256 ticketID) external;

    /** @notice This method delists a previously listed ticket of `ticketCollection` with `ticketID`. Only the account that
     * listed the ticket may delist the ticket. The ticket should be transferred back
     * to msg.sender, i.e., the lister, and escrowed bid funds should be return to the bidder, if any.
     */
    function delistTicket(address ticketCollection, uint256 ticketID) external;
}
