// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/* solhint-disable var-name-mixedcase */

contract Migrations {
    address public owner;
    uint public last_completed_migration;

    modifier restricted() {
        require(msg.sender == owner, "Migrations: caller is not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setCompleted(uint completed) public restricted {
        last_completed_migration = completed;
    }

    function upgrade(address newAddress) public restricted {
        Migrations upgraded = Migrations(newAddress);
        upgraded.setCompleted(last_completed_migration);
    }
}
