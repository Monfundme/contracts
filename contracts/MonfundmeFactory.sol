// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./MonfundmeCampaign.sol";

contract MonfundmeFactory {
    address[] public deployedCampaigns;
    address public factoryOwner;
    uint256 public platformFeePercentage = 200; // 2% default fee

    event CampaignCreated(address campaignAddress, address owner);
    event PlatformFeeUpdated(uint256 newFee);

    constructor() {
        factoryOwner = msg.sender;
    }

    function createCampaign(
        string memory _name,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _image
    ) public returns (address) {
        MonfundmeCampaign newCampaign = new MonfundmeCampaign(
            msg.sender,
            _name,
            _title,
            _description,
            _target,
            _deadline,
            _image,
            address(this),
            platformFeePercentage
        );

        deployedCampaigns.push(address(newCampaign));
        emit CampaignCreated(address(newCampaign), msg.sender);
        return address(newCampaign);
    }

    function updatePlatformFee(uint256 _newFee) external {
        require(msg.sender == factoryOwner, "Not factory owner");
        require(_newFee <= 1000, "Fee cannot exceed 10%");
        platformFeePercentage = _newFee;
        emit PlatformFeeUpdated(_newFee);
    }

    function getDeployedCampaigns() public view returns (address[] memory) {
        return deployedCampaigns;
    }
}
