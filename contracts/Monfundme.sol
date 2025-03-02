// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

contract Monfundme {
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

    event CampaignCreated(
        uint256 indexed id,
        address indexed owner,
        string title,
        uint256 target,
        uint256 deadline
    );

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

    function donateWithMON(uint256 _id, uint256 _amount) public payable {}

    function getCampaignById(
        uint256 _id
    ) public view returns (Campaign memory) {
        return activeCampaigns[_id];
    }

    function getCampaignsOfAddress(
        address _owner
    ) public view returns (Campaign[] memory) {}

    function getActiveCampaigns(
        uint256 offset,
        uint256 limit
    ) public view returns (Campaign[] memory) {}

    function getCompletedCampaigns(
        uint256 offset,
        uint256 limit
    ) public view returns (Campaign[] memory) {}
}
