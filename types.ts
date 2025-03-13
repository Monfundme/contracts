export interface CampaignParams {
    campaignOwner: string;
    title: string;
    description: string;
    image: string;
    target: bigint;
    deadline: number;
}

export interface ProposalConfig {
    proposalId: string;
    startTime: number;
    endTime: number;
    campaignParams: CampaignParams;
}
