// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract MonfundmeFactory {
    address[] public deployedCampaigns;
    address public factoryOwner;

    event CampaignCreated(address campaignAddress, address owner);

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
            factoryOwner
        );

        deployedCampaigns.push(address(newCampaign));
        emit CampaignCreated(address(newCampaign), msg.sender);
        return address(newCampaign);
    }

    function getDeployedCampaigns() public view returns (address[] memory) {
        return deployedCampaigns;
    }
}
