# Apex Database Context

![](https://img.shields.io/badge/version-1.3-brightgreen.svg) ![](https://img.shields.io/badge/build-passing-brightgreen.svg) ![](https://img.shields.io/badge/coverage-100%25-brightgreen.svg)

This library is NOT an implementation of the *[Unit of Work](https://martinfowler.com/eaaCatalog/unitOfWork.html)* pattern, because it doesn't combine DML operations to the same sObject. But it still performs all DML operations as a unit in a command design pattern way. It has the following features:

1. Easy to learn: similar APIs to the ones used with `Database` class.
2. Easy to use: 
   - No need to maintain sObject relationship dependency.
   - Automatically resolve relationships to populate parent Ids.
3. Easy to test: Provide [IDBContext Mockup](#idbcontext-mockup) for testing without permforming actual DMLs to the Database.

## Example

```java
public without sharing class AccountController {
    IDBContext dbcontext = new DBContext();

    public void doPost() {
        List<Account> accounts = new AccountService(dbcontext).createAccounts();
        List<Contact> contacts = new ContactService(dbcontext).createContacts(accounts);
        IDBResult dbResult = dbcontext.commitObjects();

        for (DMLResult dmlResult : dbResult.getResultsForInsert(Account.SObjectType)) {
            if (!dmlResult.isSuccess) {
                System.debug(dmlResult.Id);
            }
        }
    }
}
```

```java
public without sharing class AccountService {
    IDBContext dbcontext { get; set; }

    public AccountService(IDBContext dbcontext) {
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
    IDBContext dbcontext { get; set; }

    public ContactService(IDBContext dbcontext) {
        this.dbcontext = dbcontext;
    }

    public List<Contact> createContacts(List<Account> accounts) {
        List<Contact> contacts = new List<Contact>();
        for (Account account : accounts) {
            contacts.add(new Contact(
                LastName = 'Last Name ' + i,
                Account = account // ** account doesn't have an Id yet.
            ));
        }
        dbcontext.insertObjects(contacts);
        return contacts;
    }
}
```

## Usage

### Phantom Updates

This implementaion is more towards a command design pattern, so it can support "phantom" updates, such as:

```java
IDBContext dbcontext = new DBContext();
dbcontext.insertObjects(accounts);
dbcontext.updateObjects(accounts); // update the accounts as long as they 
                                   // were updated in a previsou statement
```

### Child Contexts

If some data have to be committed prior and can be committed standalone, please create a child IDBContext to perform the DMLs.

```java
IDBContext mainContext = new DBContext();
mainContext.insertObjects(accounts);

// create a child IDBContext
IDBContext childContext = mainContext.create();
childContext.insertObjects(contacts);
childContext.commitObjects();

mainContext.insertObjects(cases);
mainContext.commitObjects();
```

Child contexts don't have to be explicitly committed. `mainContext.commitObjects()` can commit any uncommitted child contextes, in the [Depth First Post Order](https://en.wikipedia.org/wiki/Tree_traversal#Post-order_(LRN)).

### IDBContext Mockup

DBContextMockup is an always-success IDBContext Implementation, no error will raised or returned. Extreme large fake ID number are assigned to the newly inserted sObjects. So the following could be possible:

```java
IDBContext dbcontext = new DBContextMockup();
List<Account> accounts = ...; // 3 new accounts without Ids
dbcontext.insertObjects(accounts);

List<Contact> contacts = [SELECT Id FROM Contact LIMIT 3];
for (Integer i = 0; i < 3; i++) {
    contacts[i].Account = accounts[i];
}
dbcontext.updateObjects(contacts);

dbcontext.commitObjects();
for (Integer i = 0; i < 3; i++) {
    System.assertEquals(accounts[i].Id, contacts[i].AccountId);
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

DMLResult class is a field combination of Database.SaveResult, Database.UpsertResult, Database.DeleteResult, Database.UndeleteResult, and Database.EmptyRecycleBinResult.

| Properties | Data Type              |
| ---------- | ---------------------- |
| errors     | List\<Database.Error\> |
| id         | Id                     |
| isSuccess  | Boolean                |
| isCreated  | Boolean                |

## License

BSD 3-Clause License
