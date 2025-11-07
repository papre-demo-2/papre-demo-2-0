// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.24;

/// @title Declarative Clause
/// @notice Anchors a Filecoin-stored Declarative Bundle and manages offer/counter/execute/cancel lifecycle
contract DeclarativeClause {
    enum Status { None, Offered, Countered, Executed, Cancelled }

    struct AgreementState {
        string bundleCID;         // Filecoin CID for Declarative Bundle JSON
        address offeror;          // Initial proposer
        address offeree;          // Counterparty (optional for open offers)
        Status status;            // Lifecycle stage
        uint256 offeredAt;        // Offer timestamp
        uint256 executedAt;       // Execution timestamp
        uint256 cancelledAt;      // Cancellation timestamp
        string counterCID;        // CID of latest counter-offer (optional)
    }

    AgreementState public agreement;

    event Offered(address indexed offeror, string bundleCID, address indexed offeree);
    event Countered(address indexed counterparty, string newBundleCID);
    event Executed(address indexed offeror, address indexed offeree, string finalBundleCID);
    event Cancelled(address indexed canceller, string reason);

    modifier onlyParticipant() {
        require(
            msg.sender == agreement.offeror || msg.sender == agreement.offeree,
            "Not a participant"
        );
        _;
    }

    /// @notice Create an offer (optionally directed to a specific offeree)
    function offer(string calldata _bundleCID, address _offeree) external {
        require(agreement.status == Status.None, "Agreement already exists");

        agreement = AgreementState({
            bundleCID: _bundleCID,
            offeror: msg.sender,
            offeree: _offeree,
            status: Status.Offered,
            offeredAt: block.timestamp,
            executedAt: 0,
            cancelledAt: 0,
            counterCID: ""
        });

        emit Offered(msg.sender, _bundleCID, _offeree);
    }

    /// @notice Submit a counteroffer with a new bundle CID.
    /// If the initial offer had no designated counterparty, the first counterparty becomes the offeree.
    function counterOffer(string calldata _bundleCID) external {
        require(
            agreement.status == Status.Offered || agreement.status == Status.Countered,
            "No active offer"
        );

        // If this was an open offer, first counterparty becomes the offeree
        if (agreement.offeree == address(0)) {
            require(msg.sender != agreement.offeror, "Offeror cannot self-counter");
            agreement.offeree = msg.sender;
        } else {
            require(msg.sender == agreement.offeree, "Not authorized counterparty");
        }

        agreement.counterCID = _bundleCID;
        agreement.status = Status.Countered;

        emit Countered(msg.sender, _bundleCID);
    }

    /// @notice Execute and record mutual assent
    function execute() external {
        require(
            agreement.status == Status.Offered || agreement.status == Status.Countered,
            "Not active"
        );
        require(
            msg.sender == agreement.offeror || msg.sender == agreement.offeree,
            "Not participant"
        );

        // For open offers, require a counterparty to exist
        require(agreement.offeree != address(0), "Counterparty not set");

        agreement.status = Status.Executed;
        agreement.executedAt = block.timestamp;

        string memory finalCID = bytes(agreement.counterCID).length > 0
            ? agreement.counterCID
            : agreement.bundleCID;

        emit Executed(agreement.offeror, agreement.offeree, finalCID);
    }

    /// @notice Cancel prior to execution
    /// If open offer, resets offeree to allow future participation
    function cancel(string calldata reason) external onlyParticipant {
        require(agreement.status != Status.Executed, "Already executed");

        agreement.status = Status.Cancelled;
        agreement.cancelledAt = block.timestamp;

        // Reset counterparty for open offers
        if (agreement.offeree != address(0) && msg.sender == agreement.offeree) {
            // If counterparty cancels, offer stays closed
            // No reset
        } else if (agreement.offeree == address(0) || msg.sender == agreement.offeror) {
            // If offeror cancels open offer, reset for future
            agreement.offeree = address(0);
        }

        emit Cancelled(msg.sender, reason);
    }
}
