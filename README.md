# Apex Database Context

![](https://img.shields.io/badge/version-1.4.1-brightgreen.svg) ![](https://img.shields.io/badge/build-passing-brightgreen.svg) ![](https://img.shields.io/badge/coverage-100%25-brightgreen.svg)

Bring Unit of Work and Repository pattern into Apex world.

## Use DBRepository

Use DBRepository to manage different sObjects context separatly.

```java
public without sharing class ContactService {
    // suggest to use a DI library to inject the following services
    IDBContext dbcontext { get; set; }
    IDBRepository accountRepository { get; set; }
    IDBRepository contactRepository { get; set; }

    public ContactService() {
        this.dbcontext = new DBContext();
        this.accountRepository = new DBRepository().config(dbcontext);
        this.contactRepository = new DBRepository().config(dbcontext);
    }

    public List<Contact> doBusiness(List<Contact> contacts) {
        for (Contact con : contacts) {
            con.FirstName = 'First Name';
            this.contactRepository.put(con); // no need to provide field list on first update

            Account acc = new Account(
                BillingCity = 'Dalian',
                BillingCountry = 'China'
            );
            this.accountRepository.add(acc);

            this.contactRepository.put(new Contact(
                    Id = con.Id,             // new contact with same Id will be merged
                    Account = acc,           // new account without Id can also be used
                    LastName = 'Last Name'
                ), new List<Schema.SObjectField> {
                    Contact.AccountId,       // use Id field to indicate the above relationship
                    Contact.LastName
                });
        }

        // saving order matters: new accounts must have Ids before update contacts
        this.accountRepository.save();       // save to DBContext only
        this.contactRepository.save(false);  // allOrNone = false

        IDBResult dbResult = dbcontext.commitObjects(); // commit to save to Salesforce
        List<DMLResult> results = dbResult.getErrorsForInsert(Contact.SObjectType);
        return contacts;
    }
}
```

## Use DBContext

### Phantom Updates

DBContext implementaion is more towards a command design pattern, so it can support "phantom" updates, such as:

```java
IDBContext dbcontext = new DBContext();
dbcontext.insertObjects(accounts);
dbcontext.updateObjects(accounts); // update the accounts as long as they
                                   // were inserted in a previsou statement
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

DBContextMock is an always-success IDBContext Implementation for unit test, no error will raised or returned. Extreme large fake ID number are assigned to the newly inserted sObjects. So the following could be possible:

```java
IDBContext dbcontext = new DBContextMock();
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

DBContextMockup can also be used with DBRepository together:

```java
IDBContext dbcontext = new DBContextMock();
IDBRepository repository = new DBRepository().config(dbcontext);
```

## APIs

### IDBRepository & DBRepository

More than a wrapper around IDBContext. It gives developer controls of the order of DML operations.

| Methods                                                      | Description                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| IDBRepository config(IDBContext *context*);                  |                                                              |
| List\<SObject\> get(String *query*)                          |                                                              |
| void add(SObject *obj*)                                      |                                                              |
| void put(SObject *obj*)                                      | First time put don't need to specify the `fields` parameter. |
| void put(SObject *obj*, List\<Schema.SObjectField\> *fields*) | Subsequent put should provide the `fields` parameter, for performance considerations. |
| void del(SObject *obj*)                                      |                                                              |
| void save()                                                  | Save to the in memory DBContext only, not perform actual DMLs to Salesforce. |
| void save(Boolean *allOrNone*)                               |                                                              |
| void save(Database.DMLOptions *options*)                     |                                                              |

### IDBContext & DBContext & DBContextMockup

Please check Salesforce [Database Class](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_methods_system_database.htm) for the descriptions of the following API counterparts.

| Methods                                                      |
| ------------------------------------------------------------ |
| IDBContext create();                                         |
| void insertObjects(List\<SObject\> *objects*)                |
| void insertObjects(List\<SObject\> *objects*, Boolean *allOrNone*) |
| void insertObjects(List\<SObject\> *objects*, Database.DMLOptions *options*) |
| void upsertObjects(List\<SObject\> *objects*)                |
| void upsertObjects(List\<SObject\> *objects*, Boolean *allOrNone*) |
| void updateObjects(List\<SObject\> *objects*)                |
| void updateObjects(List\<SObject\> *objects*, Boolean *allOrNone*) |
| void updateObjects(List\<SObject\> *objects*, Database.DMLOptions *options*) |
| void deleteObjects(List\<SObject\> *objects*)                |
| void deleteObjects(List\<SObject\> *objects*, Boolean *allOrNone*) |
| void undeleteObjects(List\<SObject\> *objects*)              |
| void undeleteObjects(List\<SObject\> *objects*, Boolean *allOrNone*) |
| void emptyRecycleBin(List\<SObject\> *objects*)              |
| IDBResult commitObjects()                                    |

### IDBResult

| Methods          |
| ---------------- |
| void rollback(); |

Use the following methods to get all results of a particular operation against an SObjectType. **Note**: Results will only be available for dml operations with `allOrNone == false` or `dmlOptions != null & dmlOptions.optAllOrNone != true`.


| Methods                                                      |
| ------------------------------------------------------------ |
| List\<DMLResult\> getResultsForInsert(Schema.SObjectType objectType) |
| List\<DMLResult\> getResultsForUpdate(Schema.SObjectType objectType) |
| List\<DMLResult\> getResultsForUpsert(Schema.SObjectType objectType) |
| List\<DMLResult\> getResultsForDelete(Schema.SObjectType objectType) |
| List\<DMLResult\> getResultsForUndelete(Schema.SObjectType objectType) |
| List\<DMLResult\> getResultsForEmptyRecycleBin(Schema.SObjectType objectType) |

Use the following methods to get only the error results of a particular operation against an SObjectType.
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
