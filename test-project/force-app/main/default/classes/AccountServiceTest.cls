/**
 * Test class for AccountService
 */
@isTest
private class AccountServiceTest {
    
    @isTest
    static void testGetAllAccounts() {
        // Create test data
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            testAccounts.add(new Account(
                Name = 'Test Account ' + i,
                Industry = 'Technology'
            ));
        }
        insert testAccounts;
        
        Test.startTest();
        List<Account> results = AccountService.getAllAccounts();
        Test.stopTest();
        
        System.assert(results.size() >= 5, 'Should return at least 5 accounts');
    }
    
    @isTest
    static void testGetAccountById() {
        Account testAccount = new Account(
            Name = 'Test Account',
            Industry = 'Finance',
            Phone = '555-1234'
        );
        insert testAccount;
        
        Test.startTest();
        Account result = AccountService.getAccountById(testAccount.Id);
        Test.stopTest();
        
        System.assertEquals(testAccount.Id, result.Id);
        System.assertEquals('Test Account', result.Name);
    }
    
    @isTest
    static void testCreateAccount() {
        Test.startTest();
        Account newAccount = AccountService.createAccount('New Test Account', 'Healthcare');
        Test.stopTest();
        
        System.assertNotEquals(null, newAccount.Id);
        System.assertEquals('New Test Account', newAccount.Name);
    }
    
    @isTest
    static void testUpdateAccountIndustry() {
        Account testAccount = new Account(
            Name = 'Test Account',
            Industry = 'Technology'
        );
        insert testAccount;
        
        Test.startTest();
        AccountService.updateAccountIndustry(testAccount.Id, 'Retail');
        Test.stopTest();
        
        Account updated = [SELECT Industry FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals('Retail', updated.Industry);
    }
}

