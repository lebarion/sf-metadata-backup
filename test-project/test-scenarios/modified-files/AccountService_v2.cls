/**
 * AccountService - Service class for Account operations
 * Version 2.0 - Updated Implementation (FOR TESTING CHANGES)
 */
public with sharing class AccountService {
    
    /**
     * Get all accounts with enhanced filtering
     */
    @AuraEnabled(cacheable=true)
    public static List<Account> getAllAccounts() {
        return [
            SELECT Id, Name, Industry, Phone, AnnualRevenue, Type 
            FROM Account 
            WHERE IsDeleted = false
            ORDER BY Name 
            LIMIT 100
        ];
    }
    
    /**
     * Get account by ID with additional fields
     */
    public static Account getAccountById(Id accountId) {
        if (accountId == null) {
            throw new IllegalArgumentException('Account ID cannot be null');
        }
        
        List<Account> accounts = [
            SELECT Id, Name, Industry, Phone, BillingCity, BillingState, 
                   BillingCountry, AnnualRevenue, NumberOfEmployees, Type
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
     * NEW METHOD: Get accounts by industry
     */
    @AuraEnabled(cacheable=true)
    public static List<Account> getAccountsByIndustry(String industry) {
        if (String.isBlank(industry)) {
            throw new IllegalArgumentException('Industry cannot be blank');
        }
        
        return [
            SELECT Id, Name, Industry, Phone, Type
            FROM Account 
            WHERE Industry = :industry 
            ORDER BY Name
            LIMIT 200
        ];
    }
    
    /**
     * Create new account with enhanced validation
     */
    public static Account createAccount(String name, String industry) {
        if (String.isBlank(name)) {
            throw new IllegalArgumentException('Account name is required');
        }
        
        // NEW: Check for duplicates
        List<Account> existingAccounts = [
            SELECT Id FROM Account WHERE Name = :name LIMIT 1
        ];
        
        if (!existingAccounts.isEmpty()) {
            throw new DmlException('Account with this name already exists');
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
    
    /**
     * NEW METHOD: Delete account
     */
    public static void deleteAccount(Id accountId) {
        if (accountId == null) {
            throw new IllegalArgumentException('Account ID cannot be null');
        }
        
        Account acc = getAccountById(accountId);
        delete acc;
    }
}

