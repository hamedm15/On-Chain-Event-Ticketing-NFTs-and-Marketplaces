// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "../lib/forge-std/src/Test.sol";
import "../src/contracts/PrimaryMarket.sol";
import "../src/contracts/SecondaryMarket.sol";
import "../src/contracts/TicketNFT.sol";
import "../src/contracts/PurchaseToken.sol";

contract SecondaryMarketTest is Test {
    PrimaryMarket private primaryMarket;
    SecondaryMarket private secondaryMarket;
    PurchaseToken private purchaseToken;
    TicketNFT private ticketNFT;

    address public creator = makeAddr("adam2");
    address public testMinter = makeAddr("bro2");
    address public testReseller = makeAddr("chin2");
    address public testBuyer = makeAddr("dan2");
    address public zero = address(0);


    function setUp() public {
        purchaseToken = new PurchaseToken();
        primaryMarket = new PrimaryMarket(purchaseToken);
        secondaryMarket = new SecondaryMarket(purchaseToken);
        payable(creator).transfer(3e18);
        payable(testMinter).transfer(2e18);
        payable(testReseller).transfer(1e18);
        payable(testBuyer).transfer(1e18);

        vm.prank(creator);
        purchaseToken.mint{value: 1e18}(); 
        vm.prank(testMinter);
        purchaseToken.mint{value: 1e18}(); 
        vm.prank(testReseller);
        purchaseToken.mint{value: 1e18}(); 
        vm.prank(testBuyer);
        purchaseToken.mint{value: 1e18}(); 
    }
    function testGetHighestBidAndBidder() public {
        uint256 initialResellerBalance = purchaseToken.balanceOf(testReseller);
        uint256 initialBuyerBalance = purchaseToken.balanceOf(testBuyer);
        uint256 initialSecMarketBalance = purchaseToken.balanceOf(address(secondaryMarket));

        vm.startPrank(creator);
        ITicketNFT ticketCollection = primaryMarket.createNewEvent("chekcing",10, 10);
        purchaseToken.approve(address(primaryMarket), 10);
        uint256 ticketId = primaryMarket.purchase(address(ticketCollection), "sellme");
        ticketCollection.approve(address(secondaryMarket), ticketId);
        secondaryMarket.listTicket(address(ticketCollection), ticketId, 20);
        vm.stopPrank();
        uint256 highestBid = secondaryMarket.getHighestBid(address(ticketCollection), ticketId);
        address highestBidder = secondaryMarket.getHighestBidder(address(ticketCollection), ticketId);
        assertEq(highestBid, 20, "Highest bid price mismatch");
        assertEq(highestBidder, zero, "Highest bidder address mismatch");
        //start biddingwar

        vm.startPrank(testReseller);
        purchaseToken.approve(address(secondaryMarket), 20);
        secondaryMarket.submitBid(address(ticketCollection), ticketId, 20 , "freemoney");
        vm.stopPrank();
        uint256 highestBid2 = secondaryMarket.getHighestBid(address(ticketCollection), ticketId);
        address highestBidder2 = secondaryMarket.getHighestBidder(address(ticketCollection), ticketId);
        assertEq(highestBid2, 20, "Highest bid price mismatch");
        assertEq(highestBidder2, testReseller, "Highest bidder address mismatch");

        vm.startPrank(testBuyer);
        purchaseToken.approve(address(secondaryMarket), 80);
        secondaryMarket.submitBid(address(ticketCollection), ticketId, 80 , "i want it");
        vm.stopPrank();
        uint256 highestBid3 = secondaryMarket.getHighestBid(address(ticketCollection), ticketId);
        address highestBidder3 = secondaryMarket.getHighestBidder(address(ticketCollection), ticketId);
        assertEq(highestBid3, 80, "Highest bid price mismatch");
        assertEq(highestBidder3, testBuyer, "Highest bidder address mismatch");

        vm.startPrank(testReseller);
        purchaseToken.approve(address(secondaryMarket), 100);
        secondaryMarket.submitBid(address(ticketCollection), ticketId, 100 , "no mine");
        vm.stopPrank();
        uint256 highestBid4 = secondaryMarket.getHighestBid(address(ticketCollection), ticketId);
        address highestBidder4 = secondaryMarket.getHighestBidder(address(ticketCollection), ticketId);
        assertEq(highestBid4, 100, "Highest bid price mismatch");
        assertEq(highestBidder4, testReseller, "Highest bidder address mismatch");


        //not curerent highest bbidder so tokens refunded
        assertEq(purchaseToken.balanceOf(testBuyer), initialBuyerBalance, "ERC20 token transfer mismatch");
        //highest bidder
        assertEq(purchaseToken.balanceOf(testReseller), initialResellerBalance - 100, "ERC20 token transfer mismatch");
        assertEq(purchaseToken.balanceOf(address(secondaryMarket)), initialSecMarketBalance + 100, "ERC20 token transfer mismatch");
    }

    function testPriceManipulation() public {
        uint256 initialMinterBalance = purchaseToken.balanceOf(testMinter);
        uint256 initialResellerBalance = purchaseToken.balanceOf(testReseller);
        uint256 initialSecMarketBalance = purchaseToken.balanceOf(address(secondaryMarket));

        vm.startPrank(testMinter);
        ITicketNFT ticketCollection = primaryMarket.createNewEvent("scamthem",10, 5);
        purchaseToken.approve(address(primaryMarket), 10);
        uint256 ticketId = primaryMarket.purchase(address(ticketCollection), "sellme");
        ticketCollection.approve(address(secondaryMarket), ticketId);
        secondaryMarket.listTicket(address(ticketCollection), ticketId, 20);
        vm.stopPrank();

        vm.startPrank(testReseller);
        purchaseToken.approve(address(secondaryMarket), 40);
        secondaryMarket.submitBid(address(ticketCollection), ticketId, 40 , "hmm goodprice");
        vm.stopPrank();

        vm.startPrank(testMinter);
        purchaseToken.approve(address(secondaryMarket), 50);
        vm.expectRevert("Seller cannot bid on his own listings");
        secondaryMarket.submitBid(address(ticketCollection), ticketId, 50 , "hahaha");
        vm.stopPrank();

        uint256 highestBid = secondaryMarket.getHighestBid(address(ticketCollection), ticketId);
        address highestBidder = secondaryMarket.getHighestBidder(address(ticketCollection), ticketId);
        assertEq(highestBid, 40, "Highest bid price mismatch");
        assertEq(highestBidder, testReseller, "Highest bidder address mismatch");

        //highest bidder
        assertEq(purchaseToken.balanceOf(testReseller), initialResellerBalance - 40, "ERC20 token transfer mismatch");
        assertEq(purchaseToken.balanceOf(address(secondaryMarket)), initialSecMarketBalance + 40, "ERC20 token transfer mismatch");
        //bid not accepted - no tokens taken from seller bidding
        assertEq(purchaseToken.balanceOf(testMinter), initialMinterBalance, "ERC20 token transfer mismatch");
    }


    function testListSubmitAccept() public {
        uint256 initialCreatorBalance = purchaseToken.balanceOf(creator);
        uint256 initialMinterBalance = purchaseToken.balanceOf(testMinter);
        uint256 initialResellerBalance = purchaseToken.balanceOf(testReseller);
        uint256 initialBuyerBalance = purchaseToken.balanceOf(testBuyer);
        uint256 initialSecMarketBalance = purchaseToken.balanceOf(address(secondaryMarket));


        vm.startPrank(creator);
        ITicketNFT ticketCollection = primaryMarket.createNewEvent("Eventresell",10, 10);
        vm.stopPrank();

        vm.startPrank(testMinter);
        purchaseToken.approve(address(primaryMarket), 10);
        uint256 ticketId = primaryMarket.purchase(address(ticketCollection), "testMinter");
        assertEq(ticketCollection.holderOf(ticketId), testMinter, "Ticket owner mismatch");

        vm.expectRevert("Caller is not owner nor approved");
        secondaryMarket.listTicket(address(ticketCollection), ticketId, 80);
        assertEq(ticketCollection.holderOf(ticketId), testMinter, "Ticket owner mismatch");

        ticketCollection.approve(address(secondaryMarket), ticketId);
        secondaryMarket.listTicket(address(ticketCollection), ticketId, 80);
        assertEq(ticketCollection.holderOf(ticketId), address(secondaryMarket), "Ticket owner mismatch");

        vm.expectRevert("No bids yet");
        secondaryMarket.acceptBid(address(ticketCollection), ticketId);
        vm.stopPrank();

        assertEq(purchaseToken.balanceOf(creator), initialCreatorBalance + 10, "ERC20 token transfer mismatch");
        assertEq(purchaseToken.balanceOf(testMinter), initialMinterBalance - 10, "ERC20 token transfer mismatch");

        vm.startPrank(testReseller);
        vm.expectRevert("ERC20: insufficient allowance");
        secondaryMarket.submitBid(address(ticketCollection), ticketId, 80 , "freemoney");
        //will fail due to no approve , so approve and try again
        purchaseToken.approve(address(secondaryMarket), 80);
        secondaryMarket.submitBid(address(ticketCollection), ticketId, 80 , "freemoney");

        vm.stopPrank();
        assertEq(purchaseToken.balanceOf(testReseller), initialResellerBalance - 80, "ERC20 token transfer mismatch");
        assertEq(purchaseToken.balanceOf(address(secondaryMarket)), initialSecMarketBalance + 80, "ERC20 token transfer mismatch");

        vm.startPrank(testBuyer);
        purchaseToken.approve(address(secondaryMarket), 100);
        vm.expectRevert("Bid too low");
        secondaryMarket.submitBid(address(ticketCollection), ticketId, 80 , "yay");
        assertEq(purchaseToken.balanceOf(testBuyer), initialBuyerBalance, "ERC20 token transfer mismatch");

        secondaryMarket.submitBid(address(ticketCollection), ticketId, 100 , "oh lets try");
        assertEq(purchaseToken.balanceOf(testBuyer), initialBuyerBalance - 100, "ERC20 token transfer mismatch");
        assertEq(purchaseToken.balanceOf(testReseller), initialResellerBalance, "ERC20 token transfer mismatch");
        assertEq(purchaseToken.balanceOf(address(secondaryMarket)), initialSecMarketBalance + 100, "ERC20 token transfer mismatch");

        vm.expectRevert("Not seller");
        secondaryMarket.acceptBid(address(ticketCollection), ticketId);
        vm.stopPrank();
        assertEq(ticketCollection.holderOf(ticketId), address(secondaryMarket), "Ticket owner mismatch");

        vm.startPrank(testMinter);
        secondaryMarket.acceptBid(address(ticketCollection), ticketId);
        vm.stopPrank();

        uint256 royalties = (100* 0.05e18)/1e18;
        //royalities and profit sent
        assertEq(purchaseToken.balanceOf(creator), initialCreatorBalance + 10 + royalties, "ERC20 token transfer mismatch");
        assertEq(purchaseToken.balanceOf(testMinter), initialMinterBalance - 10 - royalties + 100, "ERC20 token transfer mismatch");
        //buyer paid, other bidder refunded, buyer ecives ticket and holder name changes
        assertEq(purchaseToken.balanceOf(testBuyer), initialBuyerBalance - 100, "ERC20 token transfer mismatch");
        assertEq(purchaseToken.balanceOf(testReseller), initialResellerBalance, "ERC20 token transfer mismatch");
        assertEq(purchaseToken.balanceOf(address(secondaryMarket)), initialSecMarketBalance, "ERC20 token transfer mismatch");
        assertEq(ticketCollection.holderOf(ticketId), testBuyer, "Ticket owner mismatch");
        assertEq(ticketCollection.holderNameOf(ticketId), "oh lets try", "Ticket holder name mismatch");
    }

    function testInvalidListSubmitAccept() public {
        uint256 initialCreatorBalance = purchaseToken.balanceOf(creator);
        uint256 initialMinterBalance = purchaseToken.balanceOf(testMinter);
        uint256 initialResellerBalance = purchaseToken.balanceOf(testReseller);
        uint256 initialBuyerBalance = purchaseToken.balanceOf(testBuyer);
        uint256 initialSecMarketBalance = purchaseToken.balanceOf(address(secondaryMarket));

        vm.startPrank(creator);
        ITicketNFT ticketCollection = primaryMarket.createNewEvent("PARTY",10, 10);
        vm.stopPrank();

        vm.startPrank(testMinter);
        purchaseToken.approve(address(primaryMarket), 30);
        uint256 ticketId = primaryMarket.purchase(address(ticketCollection), "testMinter");
        uint256 ticketId2 = primaryMarket.purchase(address(ticketCollection), "extra1");
        uint256 ticketId3 = primaryMarket.purchase(address(ticketCollection), "extra2");
        ticketCollection.approve(address(secondaryMarket), ticketId);
        secondaryMarket.listTicket(address(ticketCollection), ticketId, 80);
        assertEq(ticketCollection.holderOf(ticketId), address(secondaryMarket), "Ticket owner mismatch");
        vm.stopPrank();

        assertEq(purchaseToken.balanceOf(creator), initialCreatorBalance + 30, "ERC20 token transfer mismatch");
        assertEq(purchaseToken.balanceOf(testMinter), initialMinterBalance - 30, "ERC20 token transfer mismatch");

        vm.startPrank(testReseller);
        purchaseToken.approve(address(secondaryMarket), 80);
        vm.expectRevert("Ticket not for sale");
        secondaryMarket.submitBid(address(ticketCollection), ticketId2, 80 , "i want2"); 
        assertEq(purchaseToken.balanceOf(testReseller), initialResellerBalance, "ERC20 token transfer mismatch");
        assertEq(purchaseToken.balanceOf(address(secondaryMarket)), initialSecMarketBalance, "ERC20 token transfer mismatch");

        secondaryMarket.submitBid(address(ticketCollection), ticketId, 80 , "i settle 1");
        assertEq(purchaseToken.balanceOf(testReseller), initialResellerBalance -80, "ERC20 token transfer mismatch");
        assertEq(purchaseToken.balanceOf(address(secondaryMarket)), initialSecMarketBalance +80, "ERC20 token transfer mismatch");
        vm.stopPrank();


        vm.startPrank(creator);
        ticketCollection.setUsed(ticketId3);
        vm.stopPrank();

        vm.startPrank(testMinter);
        ticketCollection.approve(address(secondaryMarket), ticketId3);
        vm.expectRevert("Ticket expired or used");
        secondaryMarket.listTicket(address(ticketCollection), ticketId3, 200);
        assertEq(ticketCollection.holderOf(ticketId3), testMinter, "Ticket owner mismatch");
        assertEq(ticketCollection.isExpiredOrUsed(ticketId3), true, "isExpiredOrUsed bool mismtach");

        vm.expectRevert("No active listing");
        secondaryMarket.acceptBid(address(ticketCollection), ticketId2);
        assertEq(ticketCollection.holderOf(ticketId2), testMinter, "Ticket owner mismatch");


        vm.warp(block.timestamp + (11 * 86400));
        vm.expectRevert("Ticket expired or used");
        secondaryMarket.acceptBid(address(ticketCollection), ticketId);
        assertEq(ticketCollection.isExpiredOrUsed(ticketId), true, "isExpiredOrUsed bool mismtach");
        assertEq(ticketCollection.holderOf(ticketId), address(secondaryMarket), "Ticket owner mismatch");
        assertEq(purchaseToken.balanceOf(testMinter), initialMinterBalance - 30, "ERC20 token transfer mismatch");
        assertEq(purchaseToken.balanceOf(address(secondaryMarket)), initialSecMarketBalance + 80, "ERC20 token transfer mismatch");

        ticketCollection.approve(address(secondaryMarket), ticketId2);
        vm.expectRevert("Ticket expired or used");
        secondaryMarket.listTicket(address(ticketCollection), ticketId2, 200);
        assertEq(ticketCollection.holderOf(ticketId2), testMinter, "Ticket owner mismatch");
        assertEq(ticketCollection.isExpiredOrUsed(ticketId2), true, "isExpiredOrUsed bool mismtach");
        vm.stopPrank();

        vm.startPrank(testBuyer);
        purchaseToken.approve(address(secondaryMarket), 180);
        vm.expectRevert("Ticket expired or used");
        secondaryMarket.submitBid(address(ticketCollection), ticketId, 180 , "mine1");
        assertEq(purchaseToken.balanceOf(testBuyer), initialBuyerBalance, "ERC20 token transfer mismatch");
        assertEq(purchaseToken.balanceOf(address(secondaryMarket)), initialSecMarketBalance + 80, "ERC20 token transfer mismatch");

        //sicne event expired reseller wants bid tokens back - anyone can delist and he will get refund

        secondaryMarket.delistTicket(address(ticketCollection), ticketId);

        assertEq(purchaseToken.balanceOf(testReseller), initialResellerBalance, "ERC20 token transfer mismatch");
        assertEq(purchaseToken.balanceOf(address(secondaryMarket)), initialSecMarketBalance, "ERC20 token transfer mismatch");
        vm.stopPrank();

        //delister gets useless expired ticket
        assertEq(ticketCollection.holderOf(ticketId), testBuyer, "Ticket owner mismatch");
    }

    function testDelistTicket() public {
        uint256 initialCreatorBalance = purchaseToken.balanceOf(creator);
        uint256 initialMinterBalance = purchaseToken.balanceOf(testMinter);
        uint256 initialResellerBalance = purchaseToken.balanceOf(testReseller);
        uint256 initialBuyerBalance = purchaseToken.balanceOf(testBuyer);
        uint256 initialSecMarketBalance = purchaseToken.balanceOf(address(secondaryMarket));

        vm.startPrank(creator);
        ITicketNFT ticketCollection = primaryMarket.createNewEvent("Houseparty",10, 10);
        vm.stopPrank();

        vm.startPrank(testMinter);
        purchaseToken.approve(address(primaryMarket), 30);
        uint256 ticketId = primaryMarket.purchase(address(ticketCollection), "me");
        uint256 ticketId2 = primaryMarket.purchase(address(ticketCollection), "myexgf");
        uint256 ticketId3 = primaryMarket.purchase(address(ticketCollection), "extra to sell");
        ticketCollection.approve(address(secondaryMarket), ticketId3);
        secondaryMarket.listTicket(address(ticketCollection), ticketId3, 80);
        vm.stopPrank();
        assertEq(ticketCollection.holderOf(ticketId3), address(secondaryMarket), "Ticket owner mismatch");
        assertEq(purchaseToken.balanceOf(creator), initialCreatorBalance + 30, "ERC20 token transfer mismatch");
        assertEq(purchaseToken.balanceOf(testMinter), initialMinterBalance - 30, "ERC20 token transfer mismatch");

        vm.startPrank(testBuyer);
        purchaseToken.approve(address(secondaryMarket), 100);
        secondaryMarket.submitBid(address(ticketCollection), ticketId3, 80 ,"john");
        assertEq(purchaseToken.balanceOf(testBuyer), initialBuyerBalance -80, "ERC20 token transfer mismatch");
        assertEq(purchaseToken.balanceOf(address(secondaryMarket)), initialSecMarketBalance+80, "ERC20 token transfer mismatch");
        vm.stopPrank();

        vm.startPrank(creator);
        ticketCollection.setUsed(ticketId3);
        vm.stopPrank();

        assertEq(ticketCollection.isExpiredOrUsed(ticketId3), true, "isExpiredOrUsed bool mismtach");

        vm.startPrank(testReseller);
        purchaseToken.approve(address(secondaryMarket), 100);
        vm.expectRevert("Ticket expired or used");
        secondaryMarket.submitBid(address(ticketCollection), ticketId3, 100,"will");
        assertEq(purchaseToken.balanceOf(testReseller), initialResellerBalance, "ERC20 token transfer mismatch");
        //no refund yet for prev highestbidder
        assertEq(purchaseToken.balanceOf(testBuyer), initialBuyerBalance - 80, "ERC20 token transfer mismatch");
        assertEq(purchaseToken.balanceOf(address(secondaryMarket)), initialSecMarketBalance+80, "ERC20 token transfer mismatch");
        vm.stopPrank();


        vm.startPrank(testMinter);
        vm.expectRevert("Ticket expired or used");
        secondaryMarket.acceptBid(address(ticketCollection), ticketId3);
        assertEq(ticketCollection.holderOf(ticketId3), address(secondaryMarket), "Ticket owner mismatch");
        assertEq(purchaseToken.balanceOf(testMinter), initialMinterBalance - 30, "ERC20 token transfer mismatch");
        assertEq(purchaseToken.balanceOf(address(secondaryMarket)), initialSecMarketBalance + 80, "ERC20 token transfer mismatch");


        ticketCollection.approve(address(secondaryMarket), ticketId2);
        secondaryMarket.listTicket(address(ticketCollection), ticketId2, 100);

        vm.expectRevert("No active listing");
        secondaryMarket.delistTicket(address(ticketCollection), ticketId);
        assertEq(ticketCollection.holderOf(ticketId), testMinter, "Ticket owner mismatch");
        vm.stopPrank();


        vm.startPrank(testBuyer);
        vm.expectRevert("Delister is not seller");
        secondaryMarket.delistTicket(address(ticketCollection), ticketId2);
        assertEq(ticketCollection.holderOf(ticketId2), address(secondaryMarket), "Ticket owner mismatch");

        //ticketid1 used so he can delist as non seller
        secondaryMarket.delistTicket(address(ticketCollection), ticketId3);

        assertEq(ticketCollection.isExpiredOrUsed(ticketId3), true, "Ticket owner mismatch");
        assertEq(ticketCollection.holderOf(ticketId3), testBuyer, "Ticket owner mismatch");
        assertEq(purchaseToken.balanceOf(testBuyer), initialBuyerBalance, "ERC20 token transfer mismatch");
        assertEq(purchaseToken.balanceOf(address(secondaryMarket)), initialSecMarketBalance, "ERC20 token transfer mismatch");
    }


}



