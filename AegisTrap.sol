// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ITrap} from "drosera-contracts/interfaces/ITrap.sol";

/// @title AegisTrap
/// @notice A deterministic Drosera trap for Hoodi testnet — no constructor args.
contract AegisTrap is ITrap {
    /// @notice Linked response contract (fixed at compile time).
    address public constant RESPONSE_CONTRACT = 0x1149923B9d7069757E8a6186c369B3f437617E1D;

    /// @inheritdoc ITrap
    /// @notice Called by Drosera to collect state or event data.
    /// @dev Must be view-only and never revert — return simple encoded bytes.
    function collect() external view override returns (bytes memory) {
        // Return encoded response address to verify collection
        return abi.encode(RESPONSE_CONTRACT);
    }

    /// @inheritdoc ITrap
    /// @notice Determines whether Drosera should trigger a response.
    /// @dev Must always be deterministic and non-reverting.
    function shouldRespond(bytes[] calldata data)
        external
        pure
        override
        returns (bool, bytes memory)
    {
        bool trigger = (data.length > 0 && data[0].length > 0);
        bytes memory payload = abi.encode("AegisTrigger", trigger);
        return (trigger, payload);
    }
}
