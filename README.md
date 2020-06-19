# Apex Database Context

![](https://img.shields.io/badge/version-1.1-brightgreen.svg) ![](https://img.shields.io/badge/build-passing-brightgreen.svg) ![](https://img.shields.io/badge/coverage-100%25-brightgreen.svg)

This is an easy to use *Unit of Work* pattern implementation, it has the following features:

1. DMLs are executed in the order they were added, so no need to maintain sObject relationship dependency.
2. Automatically resolve relationships to populate parent Ids.
3. Similar APIs to the ones used with `Database` class.

## Usage

```java
public without sharing class AccountController {
    IDBResult dbcontext = new DBResult();

    public void doPost() {
        List<Account> accounts = new AccountService(dbcontext).createAccounts();
        List<Contact> contacts = new ContactService(dbcontext).createContacts(accounts);
        IDBResult result = dbcontext.commitObjects();
    }
}
```

```java
public without sharing class AccountService {
    IDBResult dbcontext { get; set; }

    public AccountService(IDBResult dbcontext) {
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

**Note**: For contacts, the unsaved accounts are assigned to `Contact.Account` relationship field.  When accounts are saved, the `Contact.AccountId` will be automatically populated with the new account id.

```java
public without sharing class ContactService {
    IDBResult dbcontext { get; set; }

    public ContactService(IDBResult dbcontext) {
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

### IDBContext & DBContext

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
| IDBResult commitObjects()                        |

### IDBResult

Use the following methods to get all results of a particular operation against an SObjectType. **Note**: Results will only be available for dml operations with `allOrNone` equals to `true`.


| Methods                                                      |
| ------------------------------------------------------------ |
| List\<DMLResult\> getResultsForInsert(Schema.SObjectType objectType) |
| List\<DMLResult\> getResultsForUpdate(Schema.SObjectType objectType) |
| List\<DMLResult\> getResultsForUpsert(Schema.SObjectType objectType) |
| List\<DMLResult\> getResultsForDelete(Schema.SObjectType objectType) |
| List\<DMLResult\> getResultsForUndelete(Schema.SObjectType objectType) |
| List\<DMLResult\> getResultsForEmptyRecycleBin(Schema.SObjectType objectType) |

Use the following methods to get only the error results of a particular operation against an SObjectType
| Methods                                                      |
| ------------------------------------------------------------ |
| List\<DMLResult\> getErrorsForInsert(Schema.SObjectType objectType) |
| List\<DMLResult\> getErrorsForUpdate(Schema.SObjectType objectType) |
| List\<DMLResult\> getErrorsForUpsert(Schema.SObjectType objectType) |
| List\<DMLResult\> getErrorsForDelete(Schema.SObjectType objectType) |
| List\<DMLResult\> getErrorsForUndelete(Schema.SObjectType objectType) |
| List\<DMLResult\> getErrorsForEmptyRecycleBin(Schema.SObjectType objectType) |

### DMLResult

DMLResult contians field combination of Database.SaveResult, Database.UpsertResult, Database.DeleteResult, Database.UndeleteResult, and Database.EmptyRecycleBinResult.

| Properties | Data Type              |
| ---------- | ---------------------- |
| errors     | List\<Database.Error\> |
| id         | Id                     |
| isSuccess  | Boolean                |
| isCreated  | Boolean                |

## License

BSD 3-Clause License