// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Shareflation, ShareToken} from "../src/Shareflation.sol";

contract Attacker {}

contract ShareflationTest is Test {
    Shareflation private shareflation;
    ShareToken private shareToken;

    function setUp() public {
        shareflation = new Shareflation();
        shareToken = shareflation.token();
        vm.deal(address(this), 100 ether);
    }

    function testSwapEthSharesForToken() public {
        uint256 deposit = 1 ether;
        shareflation.swapEthSharesForToken{value: deposit}();
        assertEq(shareflation.totalETH(), deposit, "total ETH tracked");
        assertEq(shareflation.ownerShares(), 1e18, "owner shares updated");
        assertEq(shareToken.balanceOf(address(this)), 2_000_000, "tokens minted");

        shareflation.ctf();

        // try shareflation.ctf() {}
        // catch {
        //     assertTrue(false);
        // }
    }
}
