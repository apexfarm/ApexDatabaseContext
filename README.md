# Apex Database Context

![](https://img.shields.io/badge/version-1.5-brightgreen.svg) ![](https://img.shields.io/badge/build-passing-brightgreen.svg) ![](https://img.shields.io/badge/coverage-100%25-brightgreen.svg)

Bring Unit of Work and Repository pattern into Apex world.

## Usage of DBRepository

Use DBRepository to manage different sObjects context separatly. **Note**: It will be convinient to use this with [ApexDI](https://github.com/apexfarm/ApexDI), so DBContext can be registered as a singleton service.

```java
public without sharing class ContactService {
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
            this.contactRepository.modify(con);

            Account acc = (Account)this.accountRepository.create(new Account(
                BillingCity = 'Dalian',
                BillingCountry = 'China'
            ));

            Contact con = (Contact)this.contactRepository.modify(new Contact(
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
        List<DMLResult> results = dbResult.getInsertErrors(Contact.SObjectType);
        return contacts;
    }
}
```

## Usage of DBContext

### Phantom Updates

DBContext implementaion is more towards a command design pattern, so it can support "phantom" updates, such as:

```java
IDBContext dbcontext = new DBContext();
dbcontext.insertObjects(accounts);
dbcontext.updateObjects(accounts); // update the accounts as long as they
                                   // were inserted in a previsou statement
dbcontext.commitObjects();
```

### Child Contexts

If some records have to be committed prior and can be committed standalone, please create a child IDBContext to perform the DMLs.

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
| List\<SObject\> fetch(String *query*)                        |                                                              |
| SObject create(SObject *obj*)                                |                                                              |
| SObject modify(SObject *obj*)                                | First time modify don't need to specify the `fields` parameter. |
| SObject modify(SObject *obj*, List\<Schema.SObjectField\> *fields*) | Subsequent modify should provide the `fields` parameter, for performance considerations. |
| void relate(SObject *obj*, Schema.SObjectField *to*, SObject *parendObj*) | Explicitly register parent relationship. Used with `create` and `modify` APIs. |
| void remove(SObject *obj*)                                   |                                                              |
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

The method  `commitObjects()` can raise a `DBException`, if any `DMLException` occur. The advantage to catch `DBException` is that it has a `rollback()` method to rollback all the DMLs performed by the DBContext.

### IDBResult

| Methods          | Description                                                  |
| ---------------- | ------------------------------------------------------------ |
| void rollback(); | Rollback the DMLs performed by the current `commitObjects()`, but not other `commitObjects()` call. |

#### All Results

**Note**: Results will only be available for dml operations with `allOrNone == false` or `dmlOptions != null & dmlOptions.optAllOrNone != true`.


| Methods                                                      |
| ------------------------------------------------------------ |
| List\<DMLResult\> getInsertResults(Schema.SObjectType objectType) |
| List\<DMLResult\> getUpdateResults(Schema.SObjectType objectType) |
| List\<DMLResult\> getUpsertResults(Schema.SObjectType objectType) |
| List\<DMLResult\> getDeleteResults(Schema.SObjectType objectType) |
| List\<DMLResult\> getUndeleteResults(Schema.SObjectType objectType) |
| List\<DMLResult\> getEmptyRecycleBinResults(Schema.SObjectType objectType) |

#### Error Results

Use the following methods to get only the error results of a particular operation against an SObjectType.

| Methods                                                      |
| ------------------------------------------------------------ |
| List\<DMLResult\> getInsertErrors(Schema.SObjectType objectType) |
| List\<DMLResult\> getUpdateErrors(Schema.SObjectType objectType) |
| List\<DMLResult\> getUpsertErrors(Schema.SObjectType objectType) |
| List\<DMLResult\> getDeleteErrors(Schema.SObjectType objectType) |
| List\<DMLResult\> getUndeleteErrors(Schema.SObjectType objectType) |
| List\<DMLResult\> getEmptyRecycleBinErrors(Schema.SObjectType objectType) |

### DMLResult

DMLResult class is a field combination of Database.SaveResult, Database.UpsertResult, Database.DeleteResult, Database.UndeleteResult, and Database.EmptyRecycleBinResult.

| Methods     | Data Type              |
| ----------- | ---------------------- |
| getErrors() | List\<Database.Error\> |
| getId()     | Id                     |
| isSuccess() | Boolean                |
| isCreated() | Boolean                |

## License

BSD 3-Clause License
