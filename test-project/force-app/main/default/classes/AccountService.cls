/**
 * AccountService - Service class for Account operations
 * Version 1.0 - Original Implementation
 */
public with sharing class AccountService {
    
    /**
     * Get all accounts
     */
    @AuraEnabled(cacheable=true)
    public static List<Account> getAllAccounts() {
        return [SELECT Id, Name, Industry, Phone FROM Account ORDER BY Name LIMIT 100];
    }
    
    /**
     * Get account by ID
     */
    public static Account getAccountById(Id accountId) {
        if (accountId == null) {
            throw new IllegalArgumentException('Account ID cannot be null');
        }
        
        List<Account> accounts = [
            SELECT Id, Name, Industry, Phone, BillingCity, BillingState
            FROM Account 
            WHERE Id = :accountId 
            LIMIT 1
        ];
        
        if (accounts.isEmpty()) {
            throw new QueryException('Account not found');
        }
        
        return accounts[0];
    }
    
    /**
     * Create new account
     */
    public static Account createAccount(String name, String industry) {
        if (String.isBlank(name)) {
            throw new IllegalArgumentException('Account name is required');
        }
        
        Account acc = new Account(
            Name = name,
            Industry = industry
        );
        
        insert acc;
        return acc;
    }
    
    /**
     * Update account industry
     */
    public static void updateAccountIndustry(Id accountId, String newIndustry) {
        Account acc = getAccountById(accountId);
        acc.Industry = newIndustry;
        update acc;
    }
}