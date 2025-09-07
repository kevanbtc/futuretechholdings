// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library PorFreshener {
    /// @dev Tries several common setter signatures on `por` to make it fresh.
    function freshen(address por, uint256 amount, uint48 ts) internal {
        // Try: setProof(uint256,uint48)
        (bool ok, ) = por.call(abi.encodeWithSignature("setProof(uint256,uint48)", amount, ts));
        if (ok) return;

        // Try: setLatest(uint256,uint48)
        (ok, ) = por.call(abi.encodeWithSignature("setLatest(uint256,uint48)", amount, ts));
        if (ok) return;

        // Try: setLastUpdate(uint48)
        (ok, ) = por.call(abi.encodeWithSignature("setLastUpdate(uint48)", ts));
        if (ok) return;

        // Try: set(uint256,uint48)
        (ok, ) = por.call(abi.encodeWithSignature("set(uint256,uint48)", amount, ts));
        if (ok) return;

        // Final fallback: no-op; the test will still fail if none matched.
    }
}
