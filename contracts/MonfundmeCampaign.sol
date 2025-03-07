// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MonfundmeCampaign is ReentrancyGuard {
    struct Campaign {
        bytes12 _id;
        string name;
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donators;
        uint256[] donations;
    }

    Campaign public campaign;
    address public contractOwner;
    uint256 public platformFeePercentage;

    event DonationReceived(address indexed donator, uint256 amount);
    event CampaignCompleted(uint256 amountCollected);
    event CampaignClosed();
    event WithdrawalMade(address indexed to, uint256 amount);
    event FeePaid(address indexed to, uint256 amount);

    constructor(
        address _campaignOwner,
        string memory _name,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _image,
        address _contractOwner,
        uint256 _platformFeePercentage
    ) {
        require(
            _deadline > block.timestamp,
            "The deadline should be a date in the future."
        );
        require(_platformFeePercentage <= 1000, "Fee percentage too high");

        contractOwner = _contractOwner;
        platformFeePercentage = _platformFeePercentage;
        campaign._id = bytes12(
            keccak256(abi.encodePacked(block.timestamp, _campaignOwner))
        );
        campaign.owner = _campaignOwner;
        campaign.name = _name;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;
    }

    modifier onlyOwner() {
        require(
            msg.sender == contractOwner,
            "Caller is not the contract owner"
        );
        _;
    }

    modifier onlyCampaignOwner() {
        require(
            msg.sender == campaign.owner,
            "Caller is not the campaign owner"
        );
        _;
    }

    function donateWithMON() public payable nonReentrant {
        require(block.timestamp < campaign.deadline, "The campaign has ended.");
        require(msg.value > 0, "The donation amount must be greater than 0.");

        campaign.donators.push(msg.sender);
        campaign.donations.push(msg.value);
        campaign.amountCollected += msg.value;

        emit DonationReceived(msg.sender, msg.value);

        if (
            campaign.amountCollected >= campaign.target ||
            block.timestamp >= campaign.deadline
        ) {
            emit CampaignCompleted(campaign.amountCollected);
        }
    }

    function withdraw() public nonReentrant onlyCampaignOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds available to withdraw");
        require(
            block.timestamp > campaign.deadline,
            "The campaign has not ended yet."
        );

        uint256 feeAmount = (balance * platformFeePercentage) / 10000;
        uint256 withdrawAmount = balance - feeAmount;

        if (feeAmount > 0) {
            (bool feeSent, ) = payable(contractOwner).call{value: feeAmount}(
                ""
            );
            require(feeSent, "Failed to send platform fee");
            emit FeePaid(contractOwner, feeAmount);
        }

        (bool sent, ) = payable(campaign.owner).call{value: withdrawAmount}("");
        require(sent, "Failed to withdraw MON");

        emit WithdrawalMade(campaign.owner, withdrawAmount);
    }

    function getCampaignDetails()
        public
        view
        returns (
            bytes12 id,
            string memory name,
            address owner,
            string memory title,
            string memory description,
            uint256 target,
            uint256 deadline,
            uint256 amountCollected,
            string memory image,
            address[] memory donators,
            uint256[] memory donations
        )
    {
        return (
            campaign._id,
            campaign.name,
            campaign.owner,
            campaign.title,
            campaign.description,
            campaign.target,
            campaign.deadline,
            campaign.amountCollected,
            campaign.image,
            campaign.donators,
            campaign.donations
        );
    }

    function closeCampaign() public onlyOwner {
        require(campaign.owner != address(0), "Campaign does not exist.");
        emit CampaignClosed();
    }
}
