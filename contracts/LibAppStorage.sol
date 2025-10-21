// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Library for AppStorage layout with shared variables
/// @notice Provides a common storage slot for shared contract state used by facets.
library LibAppStorage {
    // Storage slot for the layout. This uses a unique keccak256 hash minus 1 to avoid collision
    bytes32 internal constant SLOT = bytes32(uint256(keccak256("papre.app.storage")) - 1);

    struct Layout {
        address owner;
        uint256 feeBps;
        bool paused;
        uint256 reentrancy;
        // add more shared variables here as needed
    }

    /// @notice Returns the storage layout for reading and writing.
    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = SLOT;
        assembly {
            s.slot := slot
        }
    }
}
