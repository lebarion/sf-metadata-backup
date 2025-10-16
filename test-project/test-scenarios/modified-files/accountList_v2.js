import { LightningElement, wire } from 'lwc';
import getAllAccounts from '@salesforce/apex/AccountService.getAllAccounts';

export default class AccountList extends LightningElement {
    accounts;
    error;

    // MODIFIED: Added more columns
    columns = [
        { label: 'Account Name', fieldName: 'Name', type: 'text' },
        { label: 'Industry', fieldName: 'Industry', type: 'text' },
        { label: 'Phone', fieldName: 'Phone', type: 'phone' },
        { label: 'Type', fieldName: 'Type', type: 'text' },
        { label: 'Annual Revenue', fieldName: 'AnnualRevenue', type: 'currency' }
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

    // NEW: Handle row selection
    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        console.log('Selected accounts:', selectedRows);
    }
}

