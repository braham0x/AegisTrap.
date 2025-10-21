README-AegisTrap
# AegisTrap.

Overview

AegisTrap is a specialized trap contract built for the Drosera CLI network (on the Hoodi testnet) that provides a deterministic, minimal-gas mechanism for monitoring on-chain activity and triggering responses.
It’s designed to serve as a guardian proxy: you deploy it, Drosera operators call its collect() function to gather a snapshot, then call shouldRespond() with recent samples. If the trap logic determines a condition is met, it signals the configured response contract.

What this trap can be used for

On-chain anomaly detection: e.g., identifying protocol slashes, oracle divergence, or stale state transitions.

Alert triggering: upon a defined condition being met, the trap outputs a payload prompting action by the response contract.

Automated response workflows: this trap acts as the first pillar of automation — you can build your custom response contract to take further action (pausing contracts, transferring funds, notifying systems).

Composable monitoring network: because it implements Drosera’s standard interface, you can integrate it alongside other traps and allow operators to uniformly manage them.

What the unique trap does

collect() returns a deterministic and lightweight bytes payload (here, encoding the fixed response contract address) so the operator can record a data point.

shouldRespond(bytes[] calldata data) takes an array of previous collect() outputs, applies a deterministic check (in this version: whether at least one sample is non-empty), and if true, returns (true, payload) where payload is ABI‐encoded for your response contract.

The response contract listens for that trigger via its respond(bytes) function and emits an event for downstream processing or alerts.

Contract Details
AegisTrap.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ITrap} from "drosera-contracts/interfaces/ITrap.sol";

/// @title AegisTrap  
/// @notice A deterministic Drosera trap for Hoodi testnet—no constructor args required.  
contract AegisTrap is ITrap {
    /// The linked response contract address (fixed at compile time)
    address public constant RESPONSE_CONTRACT = 0x1149923B9d7069757E8a6186c369B3f437617E1D;

    /// @inheritdoc ITrap
    function collect() external view override returns (bytes memory) {
        return abi.encode(RESPONSE_CONTRACT);
    }

    /// @inheritdoc ITrap
    function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
        bool trigger = (data.length > 0 && data[0].length > 0);
        bytes memory payload = abi.encode("AegisTrigger", trigger);
        return (trigger, payload);
    }
}

AegisResponse.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title AegisResponse  
/// @notice Responds when AegisTrap determines a trigger condition.  
contract AegisResponse {
    event AegisResponseTriggered(address indexed trap, address indexed responder, bytes data);

    function respond(bytes calldata data) external {
        emit AegisResponseTriggered(msg.sender, tx.origin, data);
    }
}

Testing & Interaction
Foundry Tests

If you’ve created a test script in the test/ folder, you can run:

forge test -vv


which should verify behaviours such as:

collect() returns the encoded response contract address

shouldRespond() returns correct (bool, bytes) for given sample arrays.

Cast / Manual Interaction

Once the contracts are deployed, you can test them manually:

# Replace ADDRESS_TRAP with the deployed trap contract address  
cast call --rpc-url https://ethereum-hoodi-rpc.publicnode.com ADDRESS_TRAP "collect()(bytes)"


You should receive a hex-encoded return (which should decode to your response contract address).

To test shouldRespond():

# Suppose the returned collect data is “0x…”, encode a bytes[]  
SAMPLE_HEX=$(cast abi-encode "(bytes[])" '["0x…"]')
cast call --rpc-url https://ethereum-hoodi-rpc.publicnode.com ADDRESS_TRAP "shouldRespond(bytes[])(bool,bytes)" $SAMPLE_HEX


This should return a tuple: true (or false) and a bytes‐payload (e.g., 0x416567697354726967676572…).

Deployment Details

Network: Hoodi Testnet

RPC: https://ethereum-hoodi-rpc.publicnode.com

Drosera Relay: https://relay.hoodi.drosera.io

Chain ID: 560048

Response Contract: 0x1149923B9d7069757E8a6186c369B3f437617E1D

After successfully passing drosera dryrun, you can register the trap via:

drosera deploy


Ensure your drosera.toml is correctly pointed to out/AegisTrap.sol/AegisTrap.json, and the response_contract and response_function are correctly configured.
