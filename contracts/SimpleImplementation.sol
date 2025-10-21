// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleImplementation {
    // Reserve slots 0 and 1 for proxy (implementation and owner)
    uint256 private __gap0;
    uint256 private __gap1;
    
    // Now value is in slot 2
    uint256 public value;

    function setValue(uint256 newValue) public {
        value = newValue;
    }
}