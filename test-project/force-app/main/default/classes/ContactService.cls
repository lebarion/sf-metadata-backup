/**
 * ContactService - Service class for Contact operations
 * Version 1.0 - Original Implementation
 */
public with sharing class ContactService {
    
    /**
     * Get all contacts
     */
    @AuraEnabled(cacheable=true)
    public static List<Contact> getAllContacts() {
        return [SELECT Id, FirstName, LastName, Email, Phone FROM Contact ORDER BY LastName LIMIT 100];
    }
    
    /**
     * Get contacts by account
     */
    @AuraEnabled(cacheable=true)
    public static List<Contact> getContactsByAccount(Id accountId) {
        if (accountId == null) {
            throw new IllegalArgumentException('Account ID cannot be null');
        }
        
        return [
            SELECT Id, FirstName, LastName, Email, Phone, Title
            FROM Contact 
            WHERE AccountId = :accountId 
            ORDER BY LastName
        ];
    }
    
    /**
     * Create new contact
     */
    public static Contact createContact(String firstName, String lastName, String email, Id accountId) {
        if (String.isBlank(lastName)) {
            throw new IllegalArgumentException('Last name is required');
        }
        
        Contact con = new Contact(
            FirstName = firstName,
            LastName = lastName,
            Email = email,
            AccountId = accountId
        );
        
        insert con;
        return con;
    }
}

