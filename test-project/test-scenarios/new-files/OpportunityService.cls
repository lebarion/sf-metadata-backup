/**
 * OpportunityService - NEW Service class for Opportunity operations
 * This is a NEW file to test adding metadata
 */
public with sharing class OpportunityService {
    
    /**
     * Get all opportunities
     */
    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getAllOpportunities() {
        return [
            SELECT Id, Name, StageName, Amount, CloseDate 
            FROM Opportunity 
            ORDER BY CloseDate DESC 
            LIMIT 100
        ];
    }
    
    /**
     * Get opportunity by ID
     */
    @AuraEnabled(cacheable=true)
    public static Opportunity getOpportunityById(Id oppId) {
        if (oppId == null) {
            throw new IllegalArgumentException('Opportunity ID cannot be null');
        }
        
        List<Opportunity> opps = [
            SELECT Id, Name, StageName, Amount, CloseDate, 
                   AccountId, Probability, Description
            FROM Opportunity 
            WHERE Id = :oppId 
            LIMIT 1
        ];
        
        if (opps.isEmpty()) {
            throw new QueryException('Opportunity not found');
        }
        
        return opps[0];
    }
    
    /**
     * Create new opportunity
     */
    public static Opportunity createOpportunity(
        String name, 
        Date closeDate, 
        String stageName, 
        Id accountId
    ) {
        if (String.isBlank(name)) {
            throw new IllegalArgumentException('Opportunity name is required');
        }
        
        if (closeDate == null) {
            throw new IllegalArgumentException('Close date is required');
        }
        
        Opportunity opp = new Opportunity(
            Name = name,
            CloseDate = closeDate,
            StageName = String.isNotBlank(stageName) ? stageName : 'Prospecting',
            AccountId = accountId
        );
        
        insert opp;
        return opp;
    }
}

