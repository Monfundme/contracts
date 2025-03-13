// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title MonfundmeFactory
/// @notice Factory contract for creating and managing fundraising campaigns
contract MonfundmeFactory {
    address[] public deployedCampaigns;
    address public factoryOwner;
    address public voteExecutor;
    uint256 public platformFeePercentage = 200; // 2% default fee

    event CampaignCreated(
        address indexed campaignAddress,
        address indexed owner,
        bytes12 indexed id
    );
    event PlatformFeeUpdated(uint256 newFee);
    event VoteExecutorUpdated(address indexed newExecutor);

    constructor() {
        factoryOwner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == factoryOwner, "Not factory owner");
        _;
    }

    modifier onlyVoteExecutor() {
        require(msg.sender == voteExecutor, "Only VoteExecutor can call");
        _;
    }

    /// @notice Sets the vote executor address
    /// @param _voteExecutor New vote executor address
    function setVoteExecutor(address _voteExecutor) external onlyOwner {
        require(_voteExecutor != address(0), "Invalid address");
        voteExecutor = _voteExecutor;
        emit VoteExecutorUpdated(_voteExecutor);
    }

    /// @notice Creates a new campaign
    function createCampaign(
        bytes12 _id,
        address _campaignOwner,
        string memory _title,
        string memory _description,
        string memory _image,
        uint256 _target,
        uint256 _deadline
    ) public onlyVoteExecutor returns (address) {
        require(_campaignOwner != address(0), "Invalid campaign owner address");
        require(_target > 0, "Target amount must be greater than 0");
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_description).length > 0, "Description cannot be empty");
        require(bytes(_image).length > 0, "Image URL cannot be empty");

        MonfundmeCampaign newCampaign = new MonfundmeCampaign(
            _id,
            _campaignOwner,
            _title,
            _description,
            _image,
            _target,
            _deadline,
            address(this),
            platformFeePercentage
        );

        deployedCampaigns.push(address(newCampaign));
        emit CampaignCreated(address(newCampaign), _campaignOwner, _id);
        return address(newCampaign);
    }

    /// @notice Updates the platform fee percentage
    function updatePlatformFee(uint256 _newFee) external onlyOwner {
        require(_newFee <= 1000, "Fee cannot exceed 10%");
        platformFeePercentage = _newFee;
        emit PlatformFeeUpdated(_newFee);
    }

    /// @notice Returns all deployed campaigns
    function getDeployedCampaigns() public view returns (address[] memory) {
        return deployedCampaigns;
    }

    /// @notice Receive function to allow contract to receive ETH
    receive() external payable {}

    /// @notice Fallback function to allow contract to receive ETH
    fallback() external payable {}
}

/// @title MonfundmeCampaign
/// @notice Individual campaign contract for fundraising
contract MonfundmeCampaign is ReentrancyGuard {
    enum CampaignStatus {
        Active,
        Completed,
        Closed
    }

    struct Campaign {
        bytes12 _id;
        string title;
        string description;
        string image;
        address owner;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        uint256 totalDonations;
        uint256 lastDonationTimestamp;
        CampaignStatus status;
    }

    Campaign public campaign;
    address public contractOwner;
    uint256 public platformFeePercentage;
    uint256 public constant MAX_OVERFLOW_PERCENTAGE = 200; // 200% of target

    event DonationReceived(address indexed donator, uint256 amount);
    event CampaignCompleted(uint256 amountCollected);
    event CampaignClosed(uint256 timestamp);
    event WithdrawalMade(address indexed to, uint256 amount);
    event FeePaid(address indexed to, uint256 amount);
    event TargetReached(uint256 timestamp);
    event StatusUpdated(CampaignStatus newStatus);

    constructor(
        bytes12 _id,
        address _campaignOwner,
        string memory _title,
        string memory _description,
        string memory _image,
        uint256 _target,
        uint256 _deadline,
        address _contractOwner,
        uint256 _platformFeePercentage
    ) {
        require(_deadline > block.timestamp, "Deadline must be in the future");
        require(_platformFeePercentage <= 1000, "Fee percentage too high");
        require(_campaignOwner != address(0), "Invalid owner address");
        require(_contractOwner != address(0), "Invalid contract owner address");
        require(_target > 0, "Target must be greater than 0");

        contractOwner = _contractOwner;
        platformFeePercentage = _platformFeePercentage;

        campaign._id = _id;
        campaign.title = _title;
        campaign.description = _description;
        campaign.image = _image;
        campaign.owner = _campaignOwner;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.totalDonations = 0;
        campaign.lastDonationTimestamp = 0;
        campaign.status = CampaignStatus.Active;
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Not contract owner");
        _;
    }

    modifier onlyCampaignOwner() {
        require(msg.sender == campaign.owner, "Not campaign owner");
        _;
    }

    modifier campaignActive() {
        require(
            campaign.status == CampaignStatus.Active,
            "Campaign not active"
        );
        require(block.timestamp < campaign.deadline, "Campaign ended");
        _;
    }

    /// @notice Allows users to donate to the campaign
    function donateWithMON() public payable nonReentrant campaignActive {
        require(msg.value > 0, "Donation must be greater than 0");
        require(
            campaign.amountCollected + msg.value <=
                (campaign.target * MAX_OVERFLOW_PERCENTAGE) / 100,
            "Exceeds maximum allowed amount"
        );

        campaign.amountCollected += msg.value;
        campaign.totalDonations += 1;
        campaign.lastDonationTimestamp = block.timestamp;

        emit DonationReceived(msg.sender, msg.value);

        if (campaign.amountCollected >= campaign.target) {
            campaign.status = CampaignStatus.Completed;
            emit TargetReached(block.timestamp);
            emit CampaignCompleted(campaign.amountCollected);
        }
    }

    /// @notice Allows campaign owner to withdraw funds after deadline
    function withdraw() public nonReentrant onlyCampaignOwner {
        require(block.timestamp > campaign.deadline, "Campaign still active");
        require(campaign.amountCollected > 0, "No funds to withdraw");

        uint256 balance = address(this).balance;
        uint256 feeAmount = (balance * platformFeePercentage) / 10000;
        uint256 withdrawAmount = balance - feeAmount;

        // Update state before external calls
        campaign.amountCollected = 0;
        campaign.status = CampaignStatus.Completed;

        // Process platform fee
        if (feeAmount > 0) {
            (bool feeSent, ) = payable(contractOwner).call{value: feeAmount}(
                ""
            );
            require(feeSent, "Platform fee transfer failed");
            emit FeePaid(contractOwner, feeAmount);
        }

        // Process main withdrawal
        (bool sent, ) = payable(campaign.owner).call{value: withdrawAmount}("");
        require(sent, "Withdrawal failed");

        emit WithdrawalMade(campaign.owner, withdrawAmount);
        emit StatusUpdated(CampaignStatus.Completed);
    }

    receive() external payable {
        revert("Direct transfers not allowed. Use donateWithMON() instead");
    }

    /// @notice Closes the campaign
    function closeCampaign() public onlyOwner {
        require(
            campaign.status == CampaignStatus.Active,
            "Campaign not active"
        );
        campaign.deadline = block.timestamp;
        campaign.status = CampaignStatus.Closed;
        emit CampaignClosed(block.timestamp);
        emit StatusUpdated(CampaignStatus.Closed);
    }

    /// @notice Returns all campaign details
    function getCampaignDetails()
        public
        view
        returns (
            bytes12 id,
            string memory title,
            string memory description,
            string memory image,
            address owner,
            uint256 target,
            uint256 deadline,
            uint256 amountCollected,
            uint256 totalDonations,
            uint256 lastDonationTimestamp,
            CampaignStatus status
        )
    {
        return (
            campaign._id,
            campaign.title,
            campaign.description,
            campaign.image,
            campaign.owner,
            campaign.target,
            campaign.deadline,
            campaign.amountCollected,
            campaign.totalDonations,
            campaign.lastDonationTimestamp,
            campaign.status
        );
    }
}
