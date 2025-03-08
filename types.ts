export interface CampaignParams {
    campaignOwner: string;
    metadataHash: string; // bytes32 hash
    target: bigint;
    deadline: number;
}

export interface ProposalConfig {
    proposalId: string; // bytes32 hash
    startTime: number;
    endTime: number;
    campaignParams: CampaignParams;
}
