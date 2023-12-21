// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

/**
 * @dev Required interface for the TicketNFT contract.
 * A ticket NFT is a non-fungible token that represents a single entry to an event.
 */
interface ITicketNFT {
    /**
     * @dev Emitted when `ticketID` ticket is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed ticketID
    );

    /**
     * @dev Emitted when `holder` enables `approved` to manage the `ticketID` ticket.
     */
    event Approval(
        address indexed holder,
        address indexed approved,
        uint256 indexed ticketID
    );

    /**
     * @dev Returns the address of the user who created the NFT collection
     * This is the address of the user who called `createNewEvent` in the primary market
     */
    function creator() external view returns (address);

    /**
     * @dev Returns the maximum number of tickets that can be minted for this event.
     */
    function maxNumberOfTickets() external view returns (uint256);

	/**
     * @dev Returns the name of the event for this TicketNFT
     */
    function eventName() external view returns (string memory);

    /**
     * Mints a new ticket for `holder` with `holderName`.
     * The ticket must be assigned the following metadata:
     * - A unique ticket ID. Once a ticket has been used or expired, its ID should not be reallocated
     * - An expiry time of 10 days from the time of minting
     * - A boolean `used` flag set to false
     * On minting, a `Transfer` event should be emitted with `from` set to the zero address.
     *
     * Requirements:
     *
     * - The caller must be the primary market
     */
    function mint(address holder, string memory holderName) external returns (uint256 id);

    /**
     * @dev Returns the number of tickets a `holder` has.
     */
    function balanceOf(address holder) external view returns (uint256 balance);

    /**
     * @dev Returns the address of the holder of the `ticketID` ticket.
     *
     * Requirements:
     *
     * - `ticketID` must exist.
     */
    function holderOf(uint256 ticketID) external view returns (address holder);

    /**
     * @dev Transfers `ticketID` ticket from `from` to `to`.
     * This should also set the approved address for this ticket to the zero address
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - the caller must either:
     *   - own `ticketID`
     *   - be approved to move this ticket using `approve`
     *
     * Emits a `Transfer` and an `Approval` event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 ticketID
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `ticketID` ticket to another account.
     * The approval is cleared when the ticket is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the ticket
     * - `ticketID` must exist.
     *
     * Emits an `Approval` event.
     */
    function approve(address to, uint256 ticketID) external;

    /**
     * @dev Returns the account approved for `ticketID` ticket.
     *
     * Requirements:
     *
     * - `ticketID` must exist.
     */
    function getApproved(uint256 ticketID)
        external
        view
        returns (address operator);

    /**
     * @dev Returns the current `holderName` associated with a `ticketID`.
     * Requirements:
     *
     * - `ticketID` must exist.
     */
    function holderNameOf(uint256 ticketID)
        external
        view
        returns (string memory holderName);

    /**
     * @dev Updates the `holderName` associated with a `ticketID`.
     * Note that this does not update the actual holder of the ticket.
     *
     * Requirements:
     *
     * - `ticketID` must exists
     * - Only the current holder can call this function
     */
    function updateHolderName(uint256 ticketID, string calldata newName)
        external;

    /**
     * @dev Sets the `used` flag associated with a `ticketID` to `true`
     *
     * Requirements:
     *
     * - `ticketID` must exist
     * - the ticket must not already be used
     * - the ticket must not be expired
     * - Only the creator of the collection can call this function
     */
    function setUsed(uint256 ticketID) external;

    /**
     * @dev Returns `true` if the `used` flag associated with a `ticketID` if `true`
     * or if the ticket has expired, i.e., the current time is greater than the ticket's
     * `expiryDate`.
     * Requirements:
     *
     * - `ticketID` must exist
     */
    function isExpiredOrUsed(uint256 ticketID) external view returns (bool);
}
