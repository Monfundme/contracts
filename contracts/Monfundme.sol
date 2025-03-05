// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Monfundme is ReentrancyGuard {
    struct Campaign {
        uint256 _id;
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

    mapping(uint256 => Campaign) public activeCampaigns;
    mapping(uint256 => Campaign) public completedCampaigns;
    uint256 public numberOfActiveCampaigns = 0;
    uint256 public numberOfCompletedCampaigns = 0;

    address public contractOwner;

    event CampaignCreated(
        uint256 indexed id,
        address indexed owner,
        string title,
        uint256 target,
        uint256 deadline
    );
    event CampaignCompleted(uint256 indexed id, uint256 amountCollected);
    event DonationReceived(
        uint256 indexed campaignId,
        address indexed donator,
        uint256 amount
    );
    event CampaignClosed(uint256 indexed id);

    modifier onlyOwner() {
        require(
            msg.sender == contractOwner,
            "Caller is not the contract owner"
        );
        _;
    }

    constructor() {
        contractOwner = msg.sender;
    }

    function createCampaign(
        address _owner,
        string memory _name,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _image
    ) public returns (uint256) {
        require(
            _deadline > block.timestamp,
            "The deadline should be a date in the future."
        );

        Campaign storage campaign = activeCampaigns[numberOfActiveCampaigns];
        campaign._id = numberOfActiveCampaigns;
        campaign.owner = _owner;
        campaign.name = _name;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;

        numberOfActiveCampaigns++;

        emit CampaignCreated(campaign._id, _owner, _title, _target, _deadline);
        return campaign._id;
    }

    function donateWithMON(
        uint256 _id,
        uint256 _amount
    ) public payable nonReentrant {
        Campaign storage campaign = activeCampaigns[_id];
        require(block.timestamp < campaign.deadline, "The campaign has ended.");
        require(
            msg.value == _amount,
            "Sent value does not match the donation amount."
        );

        campaign.donators.push(msg.sender);
        campaign.donations.push(_amount);
        campaign.amountCollected += _amount;

        (bool sent, ) = payable(campaign.owner).call{value: msg.value}("");
        require(sent, "Failed to send MON to campaign owner.");

        emit DonationReceived(_id, msg.sender, _amount);

        if (
            campaign.amountCollected >= campaign.target ||
            block.timestamp >= campaign.deadline
        ) {
            completedCampaigns[numberOfCompletedCampaigns] = campaign;
            numberOfCompletedCampaigns++;
            delete activeCampaigns[_id];
            numberOfActiveCampaigns--;

            emit CampaignCompleted(_id, campaign.amountCollected);
        }
    }

    function closeCampaign(uint256 _id) public onlyOwner {
        Campaign storage campaign = activeCampaigns[_id];
        require(campaign.owner != address(0), "Campaign does not exist.");

        completedCampaigns[numberOfCompletedCampaigns] = campaign;
        numberOfCompletedCampaigns++;

        delete activeCampaigns[_id];
        numberOfActiveCampaigns--;

        emit CampaignClosed(_id);
    }

    function getCampaignById(
        uint256 _id
    ) public view returns (Campaign memory) {
        return activeCampaigns[_id];
    }

    function getCampaignsOfAddress(
        address _owner
    ) public view returns (Campaign[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < numberOfActiveCampaigns; i++) {
            if (activeCampaigns[i].owner == _owner) {
                count++;
            }
        }

        Campaign[] memory result = new Campaign[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < numberOfActiveCampaigns; i++) {
            if (activeCampaigns[i].owner == _owner) {
                result[index] = activeCampaigns[i];
                index++;
            }
        }
        return result;
    }

    function getActiveCampaigns(
        uint256 offset,
        uint256 limit
    ) public view returns (Campaign[] memory) {
        uint256 available = numberOfActiveCampaigns > offset
            ? numberOfActiveCampaigns - offset
            : 0;
        uint256 length = available < limit ? available : limit;
        Campaign[] memory result = new Campaign[](length);

        for (uint256 i = 0; i < length; i++) {
            result[i] = activeCampaigns[
                numberOfActiveCampaigns - 1 - offset - i
            ];
        }
        return result;
    }

    function getCompletedCampaigns(
        uint256 offset,
        uint256 limit
    ) public view returns (Campaign[] memory) {
        uint256 available = numberOfCompletedCampaigns > offset
            ? numberOfCompletedCampaigns - offset
            : 0;
        uint256 length = available < limit ? available : limit;
        Campaign[] memory result = new Campaign[](length);

        for (uint256 i = 0; i < length; i++) {
            result[i] = completedCampaigns[offset + i];
        }
        return result;
    }
}
