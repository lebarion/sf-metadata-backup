import { LightningElement, wire } from 'lwc';
import getAllAccounts from '@salesforce/apex/AccountService.getAllAccounts';

export default class AccountList extends LightningElement {
    accounts;
    error;

    columns = [
        { label: 'Account Name', fieldName: 'Name', type: 'text' },
        { label: 'Industry', fieldName: 'Industry', type: 'text' },
        { label: 'Phone', fieldName: 'Phone', type: 'phone' }
    ];

    @wire(getAllAccounts)
    wiredAccounts({ error, data }) {
        if (data) {
            this.accounts = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.accounts = undefined;
        }
    }
}

