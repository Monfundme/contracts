// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./MonfundmeFactory.sol";

contract VoteExecutor {
    struct CampaignParams {
        address campaignOwner;
        string name;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        string image;
    }

    struct Proposal {
        bytes32 proposalHash;
        uint256 startTime;
        uint256 endTime;
        bool executed;
        bytes32 resultHash;
        CampaignParams campaignParams; // Campaign creation parameters
    }

    mapping(bytes32 => Proposal) public proposals;
    mapping(address => bool) public isValidator;
    uint256 public minValidators = 3; // Minimum validators required
    MonfundmeFactory public factory;

    event ProposalCreated(
        bytes32 indexed proposalId,
        uint256 startTime,
        uint256 endTime
    );
    event ProposalExecuted(
        bytes32 indexed proposalId,
        bytes32 resultHash,
        address campaignAddress
    );

    constructor(address _factory) {
        require(_factory != address(0), "Invalid factory address");
        isValidator[msg.sender] = true;
        factory = MonfundmeFactory(_factory);
    }

    function createProposal(
        bytes32 _proposalHash,
        uint256 _startTime,
        uint256 _endTime,
        CampaignParams calldata _campaignParams
    ) external {
        require(isValidator[msg.sender], "Not authorized");
        require(_startTime < _endTime, "Invalid time range");
        require(_startTime > block.timestamp, "Start time must be in future");
        require(
            _campaignParams.deadline > block.timestamp,
            "Campaign deadline must be in future"
        );
        require(
            _campaignParams.target > 0,
            "Target amount must be greater than 0"
        );

        proposals[_proposalHash] = Proposal({
            proposalHash: _proposalHash,
            startTime: _startTime,
            endTime: _endTime,
            executed: false,
            resultHash: bytes32(0),
            campaignParams: _campaignParams
        });

        emit ProposalCreated(_proposalHash, _startTime, _endTime);
    }

    function executeResult(
        bytes32 _proposalId,
        bytes32 _resultHash,
        bytes[] calldata _signatures
    ) external {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Already executed");
        require(block.timestamp > proposal.endTime, "Voting period not ended");
        require(_signatures.length >= minValidators, "Insufficient validators");

        // Verify signatures
        bytes32 messageHash = keccak256(
            abi.encodePacked(_proposalId, _resultHash)
        );
        _verifySignatures(messageHash, _signatures);

        // Create campaign through factory
        address newCampaign = factory.createCampaign(
            proposal.campaignParams.name,
            proposal.campaignParams.title,
            proposal.campaignParams.description,
            proposal.campaignParams.target,
            proposal.campaignParams.deadline,
            proposal.campaignParams.image
        );

        proposal.executed = true;
        proposal.resultHash = _resultHash;

        emit ProposalExecuted(_proposalId, _resultHash, newCampaign);
    }

    function _verifySignatures(
        bytes32 _messageHash,
        bytes[] calldata _signatures
    ) internal view {
        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
        );

        uint256 validSignatures = 0;
        for (uint i = 0; i < _signatures.length; i++) {
            address signer = recoverSigner(
                ethSignedMessageHash,
                _signatures[i]
            );
            if (isValidator[signer]) {
                validSignatures++;
            }
        }

        require(validSignatures >= minValidators, "Invalid signatures");
    }

    function recoverSigner(
        bytes32 _messageHash,
        bytes memory _signature
    ) internal pure returns (address) {
        require(_signature.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }

        return ecrecover(_messageHash, v, r, s);
    }
}
