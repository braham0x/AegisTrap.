// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title AegisResponse
/// @notice Handles the reaction after a trap trigger, usually called by Drosera relays.
contract AegisResponse {
    event AegisResponseTriggered(address indexed trap, address indexed responder, bytes data);

    /// @notice Called by the relay when shouldRespond() returns true.
    function respond(bytes calldata data) external {
        emit AegisResponseTriggered(msg.sender, tx.origin, data);
    }
}
