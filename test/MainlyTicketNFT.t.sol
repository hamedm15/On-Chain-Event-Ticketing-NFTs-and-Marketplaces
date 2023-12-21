// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "../lib/forge-std/src/Test.sol";
import "../src/contracts/PrimaryMarket.sol";
import "../src/contracts/TicketNFT.sol";
import "../src/contracts/PurchaseToken.sol";

contract MainlyTicketNFTTest is Test {
    PrimaryMarket private primaryMarket;
    PurchaseToken private purchaseToken;
    TicketNFT private ticketNFT;

    address public creator = makeAddr("alice");
    address public buyer = makeAddr("bob");
    address public testUser1 = makeAddr("charlie");
    address public testUser2 = makeAddr("dylan");
    address public zero = address(0);

    function setUp() public {
        purchaseToken = new PurchaseToken();
        primaryMarket = new PrimaryMarket(purchaseToken);
        payable(creator).transfer(3e18);
        payable(buyer).transfer(2e18);
        payable(testUser1).transfer(1e18);
        payable(testUser2).transfer(1e18);
        
        vm.prank(creator);
        purchaseToken.mint{value: 1e18}(); 
        vm.prank(buyer);
        purchaseToken.mint{value: 1e18}(); 
        vm.prank(testUser1);
        purchaseToken.mint{value: 1e18}(); 
    }
    function testUnAuthMint() public {
        vm.startPrank(creator);
        ITicketNFT ticketCollection = primaryMarket.createNewEvent("Event mad",10,100);
        vm.stopPrank();
        vm.startPrank(testUser1);
        vm.expectRevert("Only Primary Market can mint tickets");
        ticketCollection.mint(testUser1, "charlie");
        vm.stopPrank();
    }
    
    function testApproveAndGetApproved() public {
        vm.startPrank(creator);
        ITicketNFT ticketCollection = primaryMarket.createNewEvent("Event Bb2",10, 100);
        vm.stopPrank();

        vm.startPrank(buyer);
        purchaseToken.approve(address(primaryMarket), 10);
        uint256 ticketId = primaryMarket.purchase(address(ticketCollection), "Buyer");
        ticketCollection.approve(testUser1, ticketId);
        vm.stopPrank();

        assertEq(ticketCollection.getApproved(ticketId),testUser1,"Approved Adress MIsmacth");

        vm.startPrank(testUser1);
        ticketCollection.transferFrom(buyer, testUser1, ticketId);
        ticketCollection.updateHolderName(ticketId, "mine user1");
        vm.stopPrank();

        assertEq(ticketCollection.holderOf(ticketId), testUser1, "Ticket owner mismatch");
        assertEq(ticketCollection.holderNameOf(ticketId), "mine user1", "Ticket holder name mismatch");
        assertEq(ticketCollection.getApproved(ticketId),zero,"Approved Address did not reset");

        vm.startPrank(buyer);
        vm.expectRevert("Caller is not ticket owner");
        ticketCollection.approve(testUser1, ticketId);
        vm.stopPrank();
    }

    function testPurchaseExceedsMaxTickets() public {
        uint256 initialCreatorBalance = purchaseToken.balanceOf(creator);
        uint256 initialBuyerBalance = purchaseToken.balanceOf(buyer);
        vm.startPrank(creator);
        ITicketNFT ticketCollection = primaryMarket.createNewEvent("Event d",10, 1);
        vm.stopPrank();
        vm.startPrank(buyer);
        purchaseToken.approve(address(primaryMarket), 20);
        uint256 ticketId = primaryMarket.purchase(address(ticketCollection), "Buyer");

        vm.expectRevert("Max ticket limit reached");
        primaryMarket.purchase(address(ticketCollection), "Buyer");
        vm.stopPrank();
        assertEq(ticketCollection.holderOf(ticketId), buyer, "Ticket owner mismatch");
        assertEq(purchaseToken.balanceOf(creator), initialCreatorBalance + 10, "ERC20 token transfer mismatch");
        assertEq(purchaseToken.balanceOf(buyer), initialBuyerBalance - 10, "ERC20 token transfer mismatch");
    }

    function testPurchaseAfterTicketExpiry() public {
        vm.startPrank(creator);
        ITicketNFT ticketCollection = primaryMarket.createNewEvent("Event i ",5 ,100);
        vm.stopPrank();
        vm.warp(block.timestamp + (11 * 86400));
        vm.startPrank(buyer);
        purchaseToken.approve(address(primaryMarket), 5);
        vm.expectRevert("Event has expired");
        primaryMarket.purchase(address(ticketCollection), "Buyer");
        vm.stopPrank();
    }

    function testTransferAndCheckNewOwner() public {
        vm.startPrank(creator);
        ITicketNFT ticketCollection = primaryMarket.createNewEvent("Event q", 10, 100);
        vm.stopPrank();
        vm.startPrank(buyer);
        purchaseToken.approve(address(primaryMarket), 10);
        uint256 ticketId = primaryMarket.purchase(address(ticketCollection), "cry");
        ticketCollection.transferFrom(buyer, testUser1, ticketId);
        vm.stopPrank();

        assertEq(ticketCollection.holderOf(ticketId), testUser1);

        vm.startPrank(testUser1);
        vm.expectRevert("Transfer from incorrect owner");
        ticketCollection.transferFrom(buyer, testUser2, ticketId);
        vm.stopPrank();        
    }

    function testTransferFromBy0() public {
        vm.startPrank(creator);
        ITicketNFT ticketCollection = primaryMarket.createNewEvent("0", 10, 6);
        purchaseToken.approve(address(primaryMarket),10);
        uint256 ticketId = primaryMarket.purchase(address(ticketCollection), "minenow ");
        vm.expectRevert("Transfer to the zero/burn address");
        ticketCollection.transferFrom(creator, zero, ticketId);
        assertEq(ticketCollection.holderOf(ticketId), creator);
        vm.expectRevert("Transfer from the zero/burn address");
        ticketCollection.transferFrom(zero, buyer, ticketId);
        assertEq(ticketCollection.holderOf(ticketId), creator);
        vm.stopPrank();
    }

    function testStealTransferWithoutOwnership() public {
        vm.startPrank(creator);
        ITicketNFT ticketCollection = primaryMarket.createNewEvent("Event Steal by c", 1, 100);
        vm.stopPrank();

        vm.startPrank(buyer);
        purchaseToken.approve(address(primaryMarket), 1);
        uint256 ticketId = primaryMarket.purchase(address(ticketCollection), "haha");
        vm.stopPrank();

        vm.startPrank(creator);
        vm.expectRevert("Caller is not owner nor approved");
        ticketCollection.transferFrom(buyer,testUser1, ticketId);
        vm.stopPrank();

        vm.startPrank(testUser1);
        vm.expectRevert("Caller is not owner nor approved");
        ticketCollection.transferFrom(buyer,testUser1, ticketId);
        vm.stopPrank();

        assertEq(ticketCollection.holderOf(ticketId), buyer);

    }

    function testUpdateHolderName() public {
        vm.startPrank(creator);
        ITicketNFT ticketCollection = primaryMarket.createNewEvent("Event changename", 10, 100);
        vm.stopPrank();

        vm.startPrank(buyer);
        purchaseToken.approve(address(primaryMarket), 10);
        uint256 ticketId = primaryMarket.purchase(address(ticketCollection), "Alice");
        vm.stopPrank();

        vm.startPrank(creator);
        vm.expectRevert("Only ticket holder can update name");
        ticketCollection.updateHolderName(ticketId, "creator ");
        vm.stopPrank();
        assertEq(ticketCollection.holderNameOf(ticketId), "Alice");
        vm.startPrank(testUser1);
        vm.expectRevert("Only ticket holder can update name");
        ticketCollection.updateHolderName(ticketId, "snatch");
        vm.stopPrank();
        assertEq(ticketCollection.holderNameOf(ticketId), "Alice");

        vm.startPrank(buyer);
        ticketCollection.updateHolderName(ticketId, "buyer can change");
        vm.stopPrank();
        assertEq(ticketCollection.holderNameOf(ticketId), "buyer can change");

    }

    function testSetUsedAndIsExpiredOrUsed() public {
        vm.startPrank(creator);
        ITicketNFT ticketCollection = primaryMarket.createNewEvent("Event619", 10, 100);
        vm.stopPrank();

        vm.startPrank(buyer);
        purchaseToken.approve(address(primaryMarket), 20);
        uint256 ticketId = primaryMarket.purchase(address(ticketCollection), "buyer");
        uint256 ticketId2 = primaryMarket.purchase(address(ticketCollection), "buyer +1");
        vm.stopPrank();

        assertEq(ticketCollection.isExpiredOrUsed(ticketId), false);
        assertEq(ticketCollection.isExpiredOrUsed(ticketId2), false);


        vm.startPrank(testUser1);
        vm.expectRevert("Only creator can set ticket as used");
        ticketCollection.setUsed(ticketId2);
        vm.stopPrank();

        assertEq(ticketCollection.isExpiredOrUsed(ticketId2), false);

        vm.startPrank(creator);
        ticketCollection.setUsed(ticketId);
        assertEq(ticketCollection.isExpiredOrUsed(ticketId), true);

        vm.expectRevert("Ticket already used");
        ticketCollection.setUsed(ticketId);

        vm.warp(block.timestamp + (11 * 86400));
        assertEq(ticketCollection.isExpiredOrUsed(ticketId2), true);

        vm.startPrank(creator);
        vm.expectRevert("Event TicketNFT expired");
        ticketCollection.setUsed(ticketId2);
        vm.stopPrank();
    }

    function testTicketDoesNotExist() public {
        vm.startPrank(creator);
        ITicketNFT ticketCollection = primaryMarket.createNewEvent("Ev non", 10, 100);
        vm.expectRevert("Ticket does not exist");
        ticketCollection.setUsed(1);
        vm.expectRevert("Ticket does not exist");
        ticketCollection.isExpiredOrUsed(3);
        vm.expectRevert("Ticket does not exist");
        ticketCollection.holderNameOf(2);
        vm.expectRevert("Ticket does not exist");
        ticketCollection.approve(testUser1, 1);
        vm.expectRevert("Ticket does not exist");
        ticketCollection.getApproved(3);
        vm.expectRevert("Ticket does not exist");
        ticketCollection.updateHolderName(1,"never");
        vm.expectRevert("Ticket does not exist");
        ticketCollection.holderOf(2);
        vm.expectRevert("Ticket does not exist");
        ticketCollection.transferFrom(zero,buyer,1);
        vm.stopPrank();
    }


}
