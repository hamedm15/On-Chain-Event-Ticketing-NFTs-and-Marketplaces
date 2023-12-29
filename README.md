# On-Chain Event Ticketing: NFTs and Marketplaces in Solidity
By Hamed Mohammed

## Overview
This project develops a foundational on-chain ticketing service using Solidity, focusing on NFT-based ticket issuance and marketplace functionality. It integrates primary and secondary marketplaces for ticket creation, purchase, and bidding, with adherence to ERC721 and ERC20 standards. The implementation encompasses ticket metadata management, including event names, unique IDs, holder information, and validity timestamps. Additionally, it features admin-controlled ticket usage flags and efficient transaction handling serveing as a conceptual model, demonstrating basic blockchain ticketing functionalities.
Core components:
1. a non-fungible token (NFT) contract for implementing ticket logic,
2. a primary marketplace that allows users to create tickets (by deploying
new instances of an NFT contract) and mint these tickets in exchange for
an ERC20 token payment,
3. a secondary marketplace that allows users to create bids for tickets listed
for sale by current ticket holders.

## Contracts

- [TicketNFT Contract](src/contracts/TicketNFT.sol)
- [Primary Marketplace Contract](src/contracts/PrimaryMarket.sol)
- [Secondary Marketplace Contract](src/contracts/SecondaryMarket.sol)
- [Purchase Token Contract](src/contracts/PurchaseToken.sol) *(unchanged)*
  
## Additional Information

- The Expiry Date is set when the NFT contract is deloyed and is not tied to the time each Ticket is minted.
- When querying for the mint price of a Ticket the Event must exist.
- Tickets for an Event can only be minted via the Primary Marketplace.
- Tickets can be set as "used" by the Event Creator at **any time**.
- Sellers on the Secondary Marketplace are not allowed to bid on their own listings *(at least not from the same address haha)*.
- A listed Ticket may only be delisted by the seller unless:

  - Event has expired
  - Ticket has been used
- Immediate Refund for the Highest Bidder when:

  - Outbid by another party
  - Ticket is delisted from auction

## Test Suites

#### There is a total of 32 tests, within 4 test suites :

- [TicketNFT](test/MainlyTicketNFT.t.sol) *(This file tests the TicketNFT, PrimaryMarket and PurchaseToken contracts)*
- [Primary Marketplace](test/PrimaryMarket.t.sol)
- [Secondary Marketplace](test/SecondaryMarket.t.sol)
- [End to End](test/EndToEnd.t.sol) *(unchanged)*

Breakdown of tests for each function:

| **Function Name**    	| **Test Function Name**                   	| **Check** 	|
|----------------------	|------------------------------------------	|:---------:	|
| **Primary Market**   	|                                          	|           	|
| createNewEvent       	| _testCreateNewEvent_                     	|    PASS   	|
| purchase             	| _testPurchaseTicket_                     	|    PASS   	|
| getPrice             	| _testGetPrice_                           	|    PASS   	|
| **TicketNFT**        	|                                          	|           	|
| mint                 	| _Tested in Multiple Functions/Files_     	|    PASS   	|
| holderOf             	| _Tested in Multiple Functions/Files_     	|    PASS   	|
| transferFrom         	| _testTransferAndCheckNewOwner_           	|    PASS   	|
| approve              	| _testApproveAndGetApproved_              	|    PASS   	|
| getApproved          	| _testApproveAndGetApproved_              	|    PASS   	|
| updateHolderName     	| _testApproveAndGetApproved_              	|    PASS   	|
| setUsed              	| _testSetUsed_                            	|    PASS   	|
| isExpiredOrUsed      	| _testIsExpiredOrUsed_                    	|    PASS   	|
| holderNameOf         	| _testUpdateHolderName_                   	|           	|
| **Secondary Market** 	|                                          	|           	|
| listTicket           	| _testListSubmitAccept_                   	|    PASS   	|
| submitBid            	| _testListSubmitAccept_                   	|    PASS   	|
| getHighestBid        	| _testGetHighestBidAndBidder_             	|    PASS   	|
| getHighestBidder     	| _testGetHighestBidAndBidder_             	|    PASS   	|
| acceptBid            	| _testListSubmitAccept_                   	|    PASS   	|
| delistTicket         	| _testDelistTicket_                       	|    PASS   	|
| **PurchaseToken**    	|                                          	|           	|
| transfer             	| _Tested in Multiple Functions/Files_     	|    PASS   	|
| approve              	| _Tested in Multiple Functions/Files_     	|    PASS   	|
| transferFrom         	| _Tested in Multiple Functions/Files_     	|    PASS   	|
| increaseAllowance    	| _Tested in within other Functions/Files_ 	|    PASS   	|
| decreaseAllowance    	| _Tested in within other Functions/Files_ 	|    PASS   	|

---

## Breakdown of tests for Requirements/Vulnerabilities identified:

| **Function**         	| **Error Msg Expected**                                                      	| **Tested by**                                    	| **Check** 	|
|----------------------	|-----------------------------------------------------------------------------	|--------------------------------------------------	|:-----------:	|
| **Primary Market**   	|                                                                             	|                                                  	|             	|
| createNewEvent       	| "Event creator cannot be the zero/burn address"                             	| _testCreateNewEventApprovePurchaseBy0_           	|     PASS    	|
|                      	| "Event name cannot be   empty"                                              	| _testBadEventCreation_                           	|     PASS    	|
|                      	| "Maximum number of   tickets must be positive"                              	| _testBadEventCreation_                           	|     PASS    	|
|                      	| "Price must be   positive"                                                  	| _testBadEventCreation_                           	|     PASS    	|
| purchase             	| "ERC20: approve from the   zero address" + "ERC20: insufficient allowance"  	| _testCreateNewEventApprovePurchaseBy0_           	|     PASS    	|
|                      	| "ERC20: insufficient   allowance"                                           	| _testPurchaseNoApprovalBalance_                  	|     PASS    	|
|                      	| "ERC20: transfer amount   exceeds balance"                                  	| _testPurchaseNoApprovalBalance_                  	|     PASS    	|
| getPrice             	| "Ticket Collection Not Found"                                               	| _testNonExistentEvent_                           	|     PASS    	|
| **Secondary Market** 	|                                                                             	|                                                  	|             	|
| listTicket           	| "Ticket expired or used"                                                    	| _testInvalidListSubmitAccept_                    	|     PASS    	|
| submitBid            	| "Ticket expired or used"                                                    	| _testInvalidListSubmitAccept + testDelistTicket_ 	|     PASS    	|
|                      	| "Ticket not for   sale"                                                     	| _testInvalidListSubmitAccept_                    	|     PASS    	|
|                      	| "Bid too low"                                                               	| _testListSubmitAccept_                           	|     PASS    	|
|                      	| "Seller cannot be on his   own listings"                                    	| _testPriceManipulation_                          	|     PASS    	|
| getHighestBid        	|                                                                             	| _testGetHighestBidAndBidder_                     	|     PASS    	|
| getHighestBidder     	|                                                                             	| _testGetHighestBidAndBidder_                     	|     PASS    	|
| acceptBid            	| "No active listing"                                                         	| _testInvalidListSubmitAccept_                    	|     PASS    	|
|                      	| "Not seller"                                                                	| _testListSubmitAccept_                           	|     PASS    	|
|                      	| "No bids yet"                                                               	| _testListSubmitAccept_                           	|     PASS    	|
|                      	| "Ticket expired or   used"                                                  	| _testInvalidListSubmitAccept + testDelistTicket_ 	|     PASS    	|
| delistTicket         	| "No active listing"                                                         	| _testDelistTicket_                               	|     PASS    	|
|                      	| "Delister is not   seller"  unless expired or used                          	| _testDelistTicket_                               	|     PASS    	|
| **TicketNFT**        	|                                                                             	|                                                  	|             	|
| mint                 	| "Only Primary Market can mint tickets"                                      	| _testUnAuthMint_                                 	|     PASS    	|
|                      	| "Max ticket limit   reached"                                                	| _testPurchaseExceedsMaxTickets_                  	|     PASS    	|
|                      	| "Event has expired"                                                         	| _testPurchaseAfterTicketExpiry_                  	|     PASS    	|
| holderOf             	| "Ticket does not exist"                                                     	| _testTicketDoesNotExist_                         	|     PASS    	|
| transferFrom         	| "Transfer from incorrect owner"                                             	| _testTransferAndCheckNewOwner_                   	|     PASS    	|
|                      	| "Transfer to the   zero/burn address"                                       	| _testTransferFromBy0_                            	|     PASS    	|
|                      	| "Transfer from the   zero/burn address"                                     	| _testTransferFromBy0_                            	|     PASS    	|
|                      	| "Ticket does not   exist"                                                   	| _testTicketDoesNotExist_                         	|     PASS    	|
|                      	| "Caller is not owner nor   approved"                                        	| _testStealTransferWithoutOwnership_              	|     PASS    	|
| approve              	| "Caller is not ticket owner"                                                	| _testApproveAndGetApproved_                      	|     PASS    	|
|                      	| "Ticket does not   exist"                                                   	| _testTicketDoesNotExist_                         	|     PASS    	|
| getApproved          	| "Ticket does not exist"                                                     	| _testTicketDoesNotExist_                         	|     PASS    	|
| updateHolderName     	| "Ticket does not exist"                                                     	| _testTicketDoesNotExist_                         	|     PASS    	|
|                      	| "Only ticket holder can   update name"                                      	| _testUpdateHolderName_                           	|     PASS    	|
| setUsed              	| "Ticket does not exist"                                                     	| _testTicketDoesNotExist_                         	|     PASS    	|
|                      	| "Only creator can set   ticket as used"                                     	| _testSetUsedAndIsExpiredOrUsed_                  	|     PASS    	|
|                      	| "Ticket already   used"                                                     	| _testSetUsedAndIsExpiredOrUsed_                  	|     PASS    	|
|                      	| "Event TicketNFT   expired"                                                 	| _testSetUsedAndIsExpiredOrUsed_                  	|     PASS    	|
| isExpiredOrUsed      	| "Ticket does not exist"                                                     	| _testTicketDoesNotExist_                         	|     PASS    	|
| holderNameOf         	| "Ticket does not exist"                                                     	| _testTicketDoesNotExist_                         	|     PASS    	|

## About

Principles of Distributed Ledgers: Smart Contract Coursework for 2023, Imperial College London.
