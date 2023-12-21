// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {ITicketNFT} from "./ITicketNFT.sol";

/**
 * @dev Required interface for the primary market.
 * The primary market is the first point of sale for tickets.
 * It is responsible for minting tickets and transferring them to the purchaser.
 * The NFT to be minted is an implementation of the ITicketNFT interface and should be created (i.e. deployed)
 * when a new event NFT collection is created
 * In this implementation, the purchase price and the maximum number of tickets
 * is set when an event NFT collection is created
 * The purchase token is an ERC20 token that is specified when the contract is deployed.
 */
interface IPrimaryMarket {
    /**
     * @dev Emitted when a purchase by `holder` occurs, with `holderName` specified.
     */
    event EventCreated(
        address indexed creator,
        address indexed ticketCollection,
        string eventName,
        uint256 price,
        uint256 maxNumberOfTickets
    );

    /**
     * @dev Emitted when a purchase by `holder` occurs, with `holderName` specified.
     */
    event Purchase(
        address indexed holder,
        address indexed ticketCollection,
        uint256 ticketId,
        string holderName
    );

    /**
     *
     * @param eventName is the name of the event to create
     * @param price is the price of a single ticket for this event
     * @param maxNumberOfTickets is the maximum number of tickets that can be created for this event
     */
    function createNewEvent(
        string memory eventName,
        uint256 price,
        uint256 maxNumberOfTickets
    ) external returns (ITicketNFT ticketCollection);

    /**
     * @notice Allows a user to purchase a ticket from `ticketCollectionNFT`
     * @dev Takes the initial NFT token holder's name as a string input
     * and transfers ERC20 tokens from the purchaser to the creator of the NFT collection
     * @param ticketCollection the collection from which to buy the ticket
     * @param holderName the name of the buyer
     * @return id of the purchased ticket
     */
    function purchase(
        address ticketCollection,
        string memory holderName
    ) external returns (uint256 id);

    /**
     * @param ticketCollection the collection from which to get the price
     * @return price of a ticket for the event associated with `ticketCollection`
     */
    function getPrice(
        address ticketCollection
    ) external view returns (uint256 price);
}
