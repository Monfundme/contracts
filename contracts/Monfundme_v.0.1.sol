// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Monfundme is ReentrancyGuard {
    address public contractOwner;

    constructor() {
        contractOwner = msg.sender;
    }

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

    mapping(bytes12 => Campaign) public activeCampaigns;
    mapping(bytes12 => Campaign) public completedCampaigns;

    bytes12[] activeCampaignIds;
    bytes12[] completedCampaignIds;

    event CampaignCreated(
        bytes12 indexed campaignId,
        address indexed owner,
        string title,
        uint256 target,
        uint256 deadline
    );
    event DonationReceived(
        bytes12 indexed campaignId,
        address indexed donator,
        uint256 amount
    );
    event CampaignCompleted(bytes12 indexed id, uint256 amountCollected);
    event CampaignClosed(bytes12 indexed campaignId);

    modifier onlyOwner() {
        require(
            msg.sender == contractOwner,
            "Caller is not the contract owner"
        );
        _;
    }

    // Helper function to generate unique IDs (simplified for demonstration)
    function _generateUniqueId() internal view returns (bytes12) {
        return
            bytes12(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        msg.sender,
                        activeCampaignIds.length
                    )
                )
            );
    }

    // Helper function to remove an ID from the array
    function _removeActiveCampaignId(bytes12 _id) internal {
        for (uint256 i = 0; i < activeCampaignIds.length; i++) {
            if (activeCampaignIds[i] == _id) {
                activeCampaignIds[i] = activeCampaignIds[
                    activeCampaignIds.length - 1
                ];
                activeCampaignIds.pop();
                break;
            }
        }
    }

    function createCampaign(
        address _owner,
        string memory _name,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _image
    ) public returns (bytes12) {
        require(
            _deadline > block.timestamp,
            "The deadline should be a date in the future."
        );

        bytes12 campaignId = _generateUniqueId();

        Campaign storage campaign = activeCampaigns[campaignId];
        campaign._id = campaignId;
        campaign.owner = _owner;
        campaign.name = _name;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;

        activeCampaignIds.push(campaignId);

        emit CampaignCreated(campaignId, _owner, _title, _target, _deadline);
        return campaignId;
    }

    function donateWithMON(
        bytes12 _id,
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
            completedCampaigns[_id] = campaign;
            completedCampaignIds.push(_id);

            delete activeCampaigns[_id];
            _removeActiveCampaignId(_id);

            emit CampaignCompleted(_id, campaign.amountCollected);
        }
    }

    function getCampaignById(
        bytes12 _id
    ) public view returns (Campaign memory) {
        return activeCampaigns[_id];
    }

    function closeCampaign(bytes12 _id) public onlyOwner {
        Campaign storage campaign = activeCampaigns[_id];
        require(campaign.owner != address(0), "Campaign does not exist.");

        completedCampaigns[_id] = campaign;
        completedCampaignIds.push(_id);

        _removeActiveCampaignId(_id);

        emit CampaignClosed(_id);
    }

    function getCampaignsOfAddress(
        address _owner
    ) public view returns (Campaign[] memory) {
        uint256 count = 0;

        for (uint256 i = 0; i < activeCampaignIds.length; i++) {
            bytes12 id = activeCampaignIds[i];
            if (activeCampaigns[id].owner == _owner) {
                count++;
            }
        }

        Campaign[] memory result = new Campaign[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < activeCampaignIds.length; i++) {
            bytes12 id = activeCampaignIds[i];
            if (activeCampaigns[id].owner == _owner) {
                result[index] = activeCampaigns[id];
                index++;
            }
        }

        return result;
    }

    function getActiveCampaigns(
        uint256 offset,
        uint256 limit
    ) public view returns (Campaign[] memory) {
        uint256 available = activeCampaignIds.length > offset
            ? activeCampaignIds.length - offset
            : 0;
        uint256 length = available < limit ? available : limit;
        Campaign[] memory result = new Campaign[](length);

        for (uint256 i = 0; i < length; i++) {
            bytes12 id = activeCampaignIds[
                activeCampaignIds.length - 1 - offset - i
            ];
            result[i] = activeCampaigns[id];
        }

        return result;
    }

    function getCompletedCampaigns(
        uint256 offset,
        uint256 limit
    ) public view returns (Campaign[] memory) {
        uint256 available = completedCampaignIds.length > offset
            ? completedCampaignIds.length - offset
            : 0;
        uint256 length = available < limit ? available : limit;
        Campaign[] memory result = new Campaign[](length);

        for (uint256 i = 0; i < length; i++) {
            bytes12 id = completedCampaignIds[offset + i];
            result[i] = completedCampaigns[id];
        }

        return result;
    }

    function getNumberOfActiveCampaigns() public view returns (uint256) {
        return activeCampaignIds.length;
    }

    function getNumberOfCompletedCampaigns() public view returns (uint256) {
        return completedCampaignIds.length;
    }
}
