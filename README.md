# Apex Database Context

![](https://img.shields.io/badge/version-1.0-brightgreen.svg) ![](https://img.shields.io/badge/build-passing-brightgreen.svg) ![](https://img.shields.io/badge/coverage-95%25-brightgreen.svg)

This is an easy to use *Unit of Work* library, because:

1. No need to specify any sObject dependency order. DMLs are executed in the order they were added.
2. Automatically populate parent Ids. For example, just assign an account SObject to `Contact.Account` field. When that account is saved, its ID will be automatically assigned to `Contact.AccountId`.
3. APIs are similar to the ones used with `Database` class, therefore less learning curve. 

### Installation

| Environment           | Install Link                                                 | Version |
| --------------------- | ------------------------------------------------------------ | ------- |
| Production, Developer | <a target="_blank" href="https://login.salesforce.com/packaging/installPackage.apexp?p0=04t2v000007X3VDAA0"><img src="docs/images/deploy-button.png"></a> | ver 1.0 |
| Sandbox               | <a target="_blank" href="https://test.salesforce.com/packaging/installPackage.apexp?p0=04t2v000007X3VDAA0"><img src="docs/images/deploy-button.png"></a> | ver 1.0 |
### Performance

The performance of 8k record insertion is already close to the 10k CPU limit, this is a known issue with Salesforce. However it will be fixed in [Summer `20 release](https://success.salesforce.com/issues_view?id=a1p3A000000AT8oQAG).

## Usage

```java
public without sharing class AccountController {
    IDatabaseContext dbcontext = new DatabaseContext();

    public void doPost() {
        List<Account> accounts = new AccountService(dbcontext).createAccounts();
        List<Contact> contacts = new ContactService(dbcontext).createContacts(accounts);
        IDatabaseCommitResult result = dbcontext.commitObjects();
    }
}
```

```java
public without sharing class AccountService {
    IDatabaseContext dbcontext { get; set; }

    public AccountService(IDatabaseContext dbcontext) {
        this.dbcontext = dbcontext;
    }

    public List<Account> createAccounts() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 10; ++i) {
            accounts.add(new Account(Name = 'Parent Account ' + i));
        }
        dbcontext.insertObjects(accounts);
        return accounts;
    }
}
```

**Note**: The account is assigned to `Contact.Account` relationship field, and we don't need to set `Contact.AccountId`.  Because it can be automatically assigned with new account id, once accounts are inserted.

```java
public without sharing class ContactService {
    IDatabaseContext dbcontext { get; set; }

    public ContactService(IDatabaseContext dbcontext) {
        this.dbcontext = dbcontext;
    }

    public List<Contact> createContacts(List<Account> accounts) {
        List<Contact> contacts = new List<Contact>();
        for (Account account : accounts) {
            contacts.add(new Contact(
                LastName = 'Last Name ' + i,
                Account = account
            ));
        }
        dbcontext.insertObjects(contacts);
        return contacts;
    }
}
```

## APIs

### IDatabaseContext

Please check Salesforce [Database Class](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_methods_system_database.htm) for the descriptions of the following API counterparts.

| Methods                                                      |
| ------------------------------------------------------------ |
| void insertObjects(List\<SObject\> *objects*)                |
| void insertObjects(List\<SObject\> *objects*, Boolean *allOrNone*) |
| void upsertObjects(List\<SObject\> *objects*)                |
| void upsertObjects(List\<SObject\> *objects*, Boolean *allOrNone*) |
| void updateObjects(List\<SObject\> *objects*)                |
| void updateObjects(List\<SObject\> *objects*, Boolean *allOrNone*) |
| void deleteObjects(List\<SObject\> *objects*)                |
| void deleteObjects(List\<SObject\> *objects*, Boolean *allOrNone*) |
| void undeleteObjects(List\<SObject\> *objects*)              |
| void undeleteObjects(List\<SObject\> *objects*, Boolean *allOrNone*) |
| void emptyRecycleBin(List\<SObject\> *objects*)              |
| IDatabaseCommitResult commitObjects()                        |

### IDatabaseCommitResult

Use the following methods to get all results of a particular operation against an SObjectType. **Note**: Results will only be available for dml operations with `allOrNone` equals to `true`.


| Methods                                                      |
| ------------------------------------------------------------ |
| List<Database.SaveResult> getResultsForInsert(Schema.SObjectType objectType) |
| List<Database.SaveResult> getResultsForUpdate(Schema.SObjectType objectType) |
| List<Database.UpsertResult> getResultsForUpsert(Schema.SObjectType objectType) |
| List<Database.DeleteResult> getResultsForDelete(Schema.SObjectType objectType) |
| List<Database.UndeleteResult> getResultsForUndelete(Schema.SObjectType objectType) |
| List<Database.EmptyRecycleBinResult> getResultsForEmptyRecycleBin(Schema.SObjectType objectType) |

Use the following methods to get only the error results of a particular operation against an SObjectType
| Methods                                                      |
| ------------------------------------------------------------ |
| List<Database.SaveResult> getErrorsForInsert(Schema.SObjectType objectType) |
| List<Database.SaveResult> getErrorsForUpdate(Schema.SObjectType objectType) |
| List<Database.UpsertResult> getErrorsForUpsert(Schema.SObjectType objectType) |
| List<Database.DeleteResult> getErrorsForDelete(Schema.SObjectType objectType) |
| List<Database.UndeleteResult> getErrorsForUndelete(Schema.SObjectType objectType) |
| List<Database.EmptyRecycleBinResult> getErrorsForEmptyRecycleBin(Schema.SObjectType objectType) |

## License

BSD 3-Clause License