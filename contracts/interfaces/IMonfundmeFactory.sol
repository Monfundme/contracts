// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

interface IMonfundmeFactory {
    function createCampaign(
        bytes12 _id,
        address _campaignOwner,
        string memory _title,
        string memory _description,
        string memory _image,
        uint256 _target,
        uint256 _deadline
    ) external returns (address);

    function updatePlatformFee(uint256 _newFee) external;
    function getDeployedCampaigns() external view returns (address[] memory);
}
