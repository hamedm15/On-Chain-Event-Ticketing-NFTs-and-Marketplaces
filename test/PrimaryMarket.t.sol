// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "../lib/forge-std/src/Test.sol";
import "../src/contracts/PrimaryMarket.sol";
import "../src/contracts/TicketNFT.sol";
import "../src/contracts/PurchaseToken.sol";

contract PrimaryMarketTest is Test {
    PrimaryMarket private primaryMarket;
    PurchaseToken private purchaseToken;
    TicketNFT private ticketNFT;

    address public creator = makeAddr("alice2");
    address public buyer = makeAddr("bob2");
    address public testUser1 = makeAddr("charlie2");
    address public testUser2 = makeAddr("dilan2");
    address public zero = address(0);

    address public nonExistentEvent = makeAddr("byebye");



    function setUp() public {
        purchaseToken = new PurchaseToken();
        primaryMarket = new PrimaryMarket(purchaseToken);
        payable(creator).transfer(3e18);
        payable(buyer).transfer(2e18);
        payable(testUser1).transfer(1e18);
        
        vm.prank(creator);
        purchaseToken.mint{value: 1e18}(); 
        vm.prank(buyer);
        purchaseToken.mint{value: 1e18}(); 
        vm.prank(testUser1);
        purchaseToken.mint{value: 1e18}(); 
    }
    
    function testCreateNewEvent() public {
        vm.startPrank(creator);
        ITicketNFT ticketCollection = primaryMarket.createNewEvent("Event A",10,100);
        vm.stopPrank();
        assertEq(ticketCollection.creator(), creator, "Event creator mismatch");
        assertTrue(primaryMarket.getPrice(address(ticketCollection)) == 10, "Price mismatch");
    }
    function testPurchaseTicket() public {
        uint256 initialCreatorBalance = purchaseToken.balanceOf(creator);
        uint256 initialBuyerBalance = purchaseToken.balanceOf(buyer);
        vm.startPrank(creator);
        ITicketNFT ticketCollection = primaryMarket.createNewEvent("Event B",10, 100);
        vm.stopPrank();
        vm.startPrank(buyer);
        purchaseToken.approve(address(primaryMarket), 10);
        uint256 ticketId = primaryMarket.purchase(address(ticketCollection), "Buyer");
        vm.stopPrank();
        assertEq(ticketCollection.holderOf(ticketId), buyer, "Ticket owner mismatch");
        assertEq(purchaseToken.balanceOf(creator), initialCreatorBalance + 10, "ERC20 token transfer mismatch");
        assertEq(purchaseToken.balanceOf(buyer), initialBuyerBalance - 10, "ERC20 token transfer mismatch");
    }

    function testGetPrice() public {
        vm.startPrank(creator);
        ITicketNFT ticketCollection = primaryMarket.createNewEvent("Event c", 6 , 50);
        vm.stopPrank();
        assertEq(primaryMarket.getPrice(address(ticketCollection)),6, "Ticket price mismatch");
    }
    //just for fun haha //comment if fails
    function testNonExistentEvent() public {
        vm.startPrank(buyer);
        vm.expectRevert("Ticket Collection Not Found");
        primaryMarket.getPrice(nonExistentEvent);

        purchaseToken.approve(address(primaryMarket), 10);
        vm.expectRevert(); //EvmError 
        primaryMarket.purchase(nonExistentEvent, "NonEx");
        vm.stopPrank();
    }

    function testCreateNewEventApprovePurchaseBy0() public {
        vm.startPrank(zero);
        vm.expectRevert("Event creator cannot be the zero/burn address");
        primaryMarket.createNewEvent("willnever happen",10,100);
        vm.stopPrank();

        vm.startPrank(creator);
        ITicketNFT ticketCollection = primaryMarket.createNewEvent("samehere", 6 , 50);
        vm.stopPrank();

        vm.startPrank(zero);
        vm.expectRevert("ERC20: approve from the zero address");
        purchaseToken.approve(address(primaryMarket), 10);

        vm.expectRevert("ERC20: insufficient allowance");
        primaryMarket.purchase(address(ticketCollection), "Buyer0");
        vm.stopPrank();
    }
    
    function testCreatorBuyAndCheckOwnerandName() public {
        uint256 initialCreatorBalance = purchaseToken.balanceOf(creator);
        vm.startPrank(creator);
        ITicketNFT ticketCollection = primaryMarket.createNewEvent("Event Owner", 10, 100);
        vm.stopPrank();

        vm.startPrank(creator);
        purchaseToken.approve(address(primaryMarket), 10);
        uint256 ticketId = primaryMarket.purchase(address(ticketCollection), "YhYH");
        assertEq(ticketCollection.holderOf(ticketId), creator,"Ticket owner mismatch");
        assertEq(ticketCollection.holderNameOf(ticketId), "YhYH", "Ticket hodler name mismatch");
        assertEq(purchaseToken.balanceOf(creator), initialCreatorBalance,"token tansfer mismatch");
    }

    function testMultipleEventCreationAndPurchasing() public {
        uint256 initialCreatorBalance = purchaseToken.balanceOf(creator);
        uint256 initialBuyerBalance = purchaseToken.balanceOf(buyer);
        uint256 initialUser1Balance = purchaseToken.balanceOf(testUser1);
        vm.startPrank(creator);
        ITicketNFT ticketCollection1 = primaryMarket.createNewEvent("evj",10, 100);
        ITicketNFT ticketCollection2 = primaryMarket.createNewEvent("evk",5, 25);
        vm.stopPrank();
        assertEq(ticketCollection1.creator(), creator, "Event j creator mismatch");
        assertTrue(primaryMarket.getPrice(address(ticketCollection1)) == 10, "Price mismatch");
        assertEq(ticketCollection2.creator(), creator, "Event k creator mismatch");
        assertTrue(primaryMarket.getPrice(address(ticketCollection2)) == 5, "Price mismatch");
        
        vm.startPrank(buyer);
        purchaseToken.approve(address(primaryMarket), 15);
        uint256 ticketId1 = primaryMarket.purchase(address(ticketCollection1), "Buyer");
        uint256 ticketId2 = primaryMarket.purchase(address(ticketCollection2), "PLusone");
        vm.stopPrank();

        assertEq(ticketCollection1.holderOf(ticketId1), buyer, "Ticket owner mismatch");
        assertEq(ticketCollection1.holderNameOf(ticketId1), "Buyer", "Ticket holder name mismatch");

        assertEq(ticketCollection2.holderOf(ticketId2), buyer, "Ticket owner mismatch");
        assertEq(ticketCollection2.holderNameOf(ticketId2), "PLusone", "Ticket holder name mismatch");

        assertEq(purchaseToken.balanceOf(creator), initialCreatorBalance + 15, "ERC20 token transfer mismatch");
        assertEq(purchaseToken.balanceOf(buyer), initialBuyerBalance - 15, "ERC20 token transfer mismatch");

        vm.startPrank(testUser1);
        purchaseToken.approve(address(primaryMarket), 15);
        uint256 ticketId3 = primaryMarket.purchase(address(ticketCollection1), "mymy");
        uint256 ticketId4 = primaryMarket.purchase(address(ticketCollection2), "bros");
        vm.stopPrank();

        assertEq(ticketCollection1.holderOf(ticketId3), testUser1, "Ticket owner mismatch");
        assertEq(ticketCollection1.holderNameOf(ticketId3), "mymy", "Ticket holder name mismatch");

        assertEq(ticketCollection2.holderOf(ticketId4), testUser1, "Ticket owner mismatch");
        assertEq(ticketCollection2.holderNameOf(ticketId4), "bros", "Ticket holder name mismatch");

        assertEq(purchaseToken.balanceOf(creator), initialCreatorBalance + 30, "ERC20 token transfer mismatch");
        assertEq(purchaseToken.balanceOf(testUser1), initialUser1Balance - 15, "ERC20 token transfer mismatch");

    }

    function testBadEventCreation() public {
        vm.startPrank(creator);
        vm.expectRevert("Event name cannot be empty");
        primaryMarket.createNewEvent("", 10, 5);
        vm.expectRevert("Maximum number of tickets must be positive");
        primaryMarket.createNewEvent("Event f", 10, 0);
        vm.expectRevert("Price must be positive");
        primaryMarket.createNewEvent("Event g", 0, 38);
        vm.stopPrank();
    }

    function testPurchaseNoApprovalBalance() public {
        vm.startPrank(creator);
        ITicketNFT ticketCollection = primaryMarket.createNewEvent("Event h",500000, 100);
        vm.stopPrank();

        vm.startPrank(buyer);
        purchaseToken.approve(address(primaryMarket), 0);
        assertEq(purchaseToken.allowance(buyer,address(primaryMarket)),0, " token allowance mismatch");
        vm.expectRevert("ERC20: insufficient allowance");
        primaryMarket.purchase(address(ticketCollection), "Buyer1");

        purchaseToken.approve(address(primaryMarket), 100);
        vm.expectRevert("ERC20: insufficient allowance");
        primaryMarket.purchase(address(ticketCollection), "Buyer2");
        assertEq(purchaseToken.allowance(buyer,address(primaryMarket)),100, " token allowance mismatch");
        vm.stopPrank();

        assertEq(purchaseToken.balanceOf(testUser2) >= 5e5 , false, "user2 balance too much");
        vm.startPrank(testUser2);
        purchaseToken.approve(address(primaryMarket), 5e5);
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        primaryMarket.purchase(address(ticketCollection), "im broke");
        vm.stopPrank();


    }
}
