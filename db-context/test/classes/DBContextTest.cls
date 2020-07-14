/**
 * BSD 3-Clause License
 *
 * Copyright (c) 2020, https://github.com/apexfarm/ApexDatabaseContext
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

@IsTest
public with sharing class DBContextTest {
    @IsTest
    static void test_without_dml() {
        IDBContext dbcontext = new DBContext();
        IDBResult result = dbcontext.commitObjects();

        System.assertEquals(0, result.getInsertResults(Account.SObjectType).size());
        System.assertEquals(0, result.getUpdateResults(Account.SObjectType).size());
        System.assertEquals(0, result.getUpsertResults(Account.SObjectType).size());
        System.assertEquals(0, result.getDeleteResults(Account.SObjectType).size());
        System.assertEquals(0, result.getUndeleteResults(Account.SObjectType).size());
        System.assertEquals(0, result.getEmptyRecycleBinResults(Account.SObjectType).size());

        System.assertEquals(0, result.getInsertErrors(Account.SObjectType).size());
        System.assertEquals(0, result.getUpdateErrors(Account.SObjectType).size());
        System.assertEquals(0, result.getUpsertErrors(Account.SObjectType).size());
        System.assertEquals(0, result.getDeleteErrors(Account.SObjectType).size());
        System.assertEquals(0, result.getUndeleteErrors(Account.SObjectType).size());
        System.assertEquals(0, result.getEmptyRecycleBinErrors(Account.SObjectType).size());
    }

    @IsTest
    static void test_AllOrNone_null_list() {
        IDBContext dbcontext = new DBContext();
        dbcontext.insertObjects(null);
        dbcontext.upsertObjects(null);
        dbcontext.updateObjects(null);
        dbcontext.commitObjects();
    }

    @IsTest
    static void test_AllOrNone_empty_list() {
        IDBContext dbcontext = new DBContext();
        dbcontext.insertObjects(new List<Account> {});
        dbcontext.upsertObjects(new List<Account> {});
        dbcontext.updateObjects(new List<Account> {});
        dbcontext.deleteObjects(new List<Account> {});
        dbcontext.undeleteObjects(new List<Account> {});
        dbcontext.emptyRecycleBin(new List<Account> {});
        dbcontext.deleteObjects(new List<Id> {});
        dbcontext.undeleteObjects(new List<Id> {});
        dbcontext.emptyRecycleBin(new List<Id> {});
        dbcontext.commitObjects();
    }

    @IsTest
    static void test_AllOrNone_empty_list2() {
        IDBContext dbcontext = new DBContext();
        dbcontext.insertObjects(new List<Account> {}, true);
        dbcontext.upsertObjects(new List<Account> {}, true);
        dbcontext.updateObjects(new List<Account> {}, true);
        dbcontext.deleteObjects(new List<Account> {}, true);
        dbcontext.undeleteObjects(new List<Account> {}, true);
        dbcontext.emptyRecycleBin(new List<Account> {}, true);
        dbcontext.deleteObjects(new List<Id> {}, true);
        dbcontext.undeleteObjects(new List<Id> {}, true);
        dbcontext.emptyRecycleBin(new List<Id> {}, true);
        IDBResult result = dbcontext.commitObjects();

        System.assertEquals(0, result.getInsertErrors(Account.SObjectType).size());
        System.assertEquals(0, result.getUpdateErrors(Account.SObjectType).size());
        System.assertEquals(0, result.getUpsertErrors(Account.SObjectType).size());
        System.assertEquals(0, result.getDeleteErrors(Account.SObjectType).size());
        System.assertEquals(0, result.getUndeleteErrors(Account.SObjectType).size());
        System.assertEquals(0, result.getEmptyRecycleBinErrors(Account.SObjectType).size());
    }

    @IsTest
    static void test_partial_insert_dmlResult() {
        IDBContext dbcontext = new DBContext();
        Account acc = new Account();
        dbcontext.insertObjects(new List<Account> { acc }, false);
        IDBResult dbresult = dbcontext.commitObjects();
        List<DMLResult> results = dbresult.getInsertResults(Account.SObjectType);

        System.assertEquals(1, results.size());
        DMLResult result = results[0];
        System.assertEquals(false, result.isSuccess());
        System.assertEquals(true, result.isCreated());
        System.assertNotEquals(null, result.getErrors());
        System.assertEquals(null, result.getId());
        System.assertEquals(null, acc.Id);
    }

    @IsTest
    static void test_partial_update_dmlResult() {
        IDBContext dbcontext = new DBContext();
        Account acc = new Account(
            Id = DBContextMock.getFakeId(Account.SObjectType)
        );
        dbcontext.updateObjects(new List<Account> { acc }, false);
        IDBResult dbresult = dbcontext.commitObjects();
        List<DMLResult> results = dbresult.getUpdateResults(Account.SObjectType);

        System.assertEquals(1, results.size());
        DMLResult result = results[0];
        System.assertEquals(false, result.isSuccess());
        System.assertEquals(false, result.isCreated());
        System.assertNotEquals(null, result.getErrors());
        System.assertEquals(null, result.getId());
    }

    @IsTest
    static void test_AllOrNone_exception_rollback() {
        IDBContext dbcontext = new DBContext();
        Boolean hasException = false;
        try {
            dbcontext.commitObjects();
            dbcontext.insertObjects(new List<Account> { new Account() });
            dbcontext.commitObjects();
        } catch(DBException ex) {
            hasException = true;
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug(ex.getCause());
            System.debug(ex.getLineNumber());
            System.debug(ex.getDmlFieldNames(0));
            System.debug(ex.getDmlFields(0));
            System.debug(ex.getDmlId(0));
            System.debug(ex.getDmlIndex(0));
            System.debug(ex.getDmlMessage(0));
            System.debug(ex.getDmlStatusCode(0));
            System.debug(ex.getDmlType(0));
            System.debug(ex.getNumDml());
            ex.rollback();
        }
        System.assertEquals(true, hasException);
    }

    @IsTest
    static void test_partial_exception_rollback() {
        IDBContext dbcontext = new DBContext();
        Boolean hasException = false;
        Boolean hasRollback = false;
        try {
            dbcontext.commitObjects();

            dbcontext.insertObjects(new List<Account> { new Account() }, false);
            IDBResult dbresult1 = dbcontext.commitObjects();

            dbcontext.insertObjects(new List<Account> { new Account() }, false);
            IDBResult dbresult2 = dbcontext.commitObjects();

            dbresult2.rollback();
            dbresult1.rollback();
            hasRollback = true;

            dbcontext.insertObjects(new List<Account> { new Account() });
            dbcontext.commitObjects();
            hasRollback = false;
        } catch(DBException ex) {
            hasException = true;
            ex.rollback();
            ex.rollback();
        }
        System.assertEquals(true, hasException);
        System.assertEquals(true, hasRollback);
    }

    @IsTest
    static void test_partial_empty_list() {
        IDBContext dbcontext = new DBContext();
        dbcontext.insertObjects(new List<Account> {}, false);
        dbcontext.upsertObjects(new List<Account> {}, false);
        dbcontext.updateObjects(new List<Account> {}, false);
        dbcontext.deleteObjects(new List<Account> {}, false);
        dbcontext.undeleteObjects(new List<Account> {}, false);
        dbcontext.emptyRecycleBin(new List<Account> {}, false);
        dbcontext.deleteObjects(new List<Id> {}, false);
        dbcontext.undeleteObjects(new List<Id> {}, false);
        dbcontext.emptyRecycleBin(new List<Id> {}, false);
        IDBResult result = dbcontext.commitObjects();

        System.assertEquals(0, result.getInsertErrors(Account.SObjectType).size());
        System.assertEquals(0, result.getUpdateErrors(Account.SObjectType).size());
        System.assertEquals(0, result.getUpsertErrors(Account.SObjectType).size());
        System.assertEquals(0, result.getDeleteErrors(Account.SObjectType).size());
        System.assertEquals(0, result.getUndeleteErrors(Account.SObjectType).size());
        System.assertEquals(0, result.getEmptyRecycleBinErrors(Account.SObjectType).size());
    }

    @IsTest
    static void test_partial_one_object_list() {
        IDBContext dbcontext = new DBContext();
        dbcontext.insertObjects(new List<Account> { new Account() }, false);
        dbcontext.upsertObjects(new List<Account> { new Account() }, false);
        dbcontext.updateObjects(new List<Account> { new Account(Id = DBContextMock.getFakeId(Account.SObjectType)) }, false);
        dbcontext.deleteObjects(new List<Account> { new Account(Id = DBContextMock.getFakeId(Account.SObjectType)) }, false);
        dbcontext.undeleteObjects(new List<Account> { new Account(Id = DBContextMock.getFakeId(Account.SObjectType)) }, false);
        dbcontext.emptyRecycleBin(new List<Account> { new Account(Id = DBContextMock.getFakeId(Account.SObjectType)) }, false);
        dbcontext.emptyRecycleBin(new List<Account> { new Account(Id = DBContextMock.getFakeId(Account.SObjectType)) }, true);
        dbcontext.deleteObjects(new List<Id> { DBContextMock.getFakeId(Account.SObjectType) }, false);
        dbcontext.undeleteObjects(new List<Id> { DBContextMock.getFakeId(Account.SObjectType) }, false);
        dbcontext.emptyRecycleBin(new List<Id> { DBContextMock.getFakeId(Account.SObjectType) }, false);
        IDBResult result = dbcontext.commitObjects();

        System.assertEquals(1, result.getInsertErrors(Account.SObjectType).size());
        System.assertEquals(1, result.getUpdateErrors(Account.SObjectType).size());
        System.assertEquals(1, result.getUpsertErrors(Account.SObjectType).size());
        System.assertEquals(2, result.getDeleteErrors(Account.SObjectType).size());
        System.assertEquals(2, result.getUndeleteErrors(Account.SObjectType).size());
        System.assertEquals(2, result.getEmptyRecycleBinErrors(Account.SObjectType).size());

        System.assertEquals(1, result.getInsertResults(Account.SObjectType).size());
        System.assertEquals(1, result.getUpdateResults(Account.SObjectType).size());
        System.assertEquals(1, result.getUpsertResults(Account.SObjectType).size());
        System.assertEquals(2, result.getDeleteResults(Account.SObjectType).size());
        System.assertEquals(2, result.getUndeleteResults(Account.SObjectType).size());
        System.assertEquals(2, result.getEmptyRecycleBinResults(Account.SObjectType).size());
    }

    @IsTest
    static void test_partial_dmloptions() {
        IDBContext dbcontext = new DBContext();
        Database.DMLOptions dmlOptions = new Database.DMLOptions();
        dbcontext.insertObjects(new List<Account> { new Account() }, dmlOptions);
        dbcontext.updateObjects(new List<Account> { new Account(Id = DBContextMock.getFakeId(Account.SObjectType)) }, dmlOptions);
        IDBResult result = dbcontext.commitObjects();

        System.assertEquals(1, result.getInsertErrors(Account.SObjectType).size());
        System.assertEquals(1, result.getUpdateErrors(Account.SObjectType).size());

        System.assertEquals(1, result.getInsertResults(Account.SObjectType).size());
        System.assertEquals(1, result.getUpdateResults(Account.SObjectType).size());
    }

    @IsTest
    static void test_partial_one_object_list_child_context() {
        IDBContext dbcontext = new DBContext();
        IDBContext childContext1 = dbcontext.create();
        IDBContext childContext2 = dbcontext.create();
        childContext1.insertObjects(new List<Account> { new Account() }, false);
        childContext2.upsertObjects(new List<Account> { new Account() }, false);
        childContext1.updateObjects(new List<Account> { new Account(Id = DBContextMock.getFakeId(Account.SObjectType)) }, false);
        childContext2.deleteObjects(new List<Account> { new Account(Id = DBContextMock.getFakeId(Account.SObjectType)) }, false);
        childContext1.undeleteObjects(new List<Account> { new Account(Id = DBContextMock.getFakeId(Account.SObjectType)) }, false);
        childContext2.emptyRecycleBin(new List<Account> { new Account(Id = DBContextMock.getFakeId(Account.SObjectType)) }, false);
        childContext1.emptyRecycleBin(new List<Account> { new Account(Id = DBContextMock.getFakeId(Account.SObjectType)) }, true);
        IDBResult result = dbcontext.commitObjects();

        System.assertEquals(1, result.getInsertErrors(Account.SObjectType).size());
        System.assertEquals(1, result.getUpdateErrors(Account.SObjectType).size());
        System.assertEquals(1, result.getUpsertErrors(Account.SObjectType).size());
        System.assertEquals(1, result.getDeleteErrors(Account.SObjectType).size());
        System.assertEquals(1, result.getUndeleteErrors(Account.SObjectType).size());
        System.assertEquals(1, result.getEmptyRecycleBinErrors(Account.SObjectType).size());

        System.assertEquals(1, result.getInsertResults(Account.SObjectType).size());
        System.assertEquals(1, result.getUpdateResults(Account.SObjectType).size());
        System.assertEquals(1, result.getUpsertResults(Account.SObjectType).size());
        System.assertEquals(1, result.getDeleteResults(Account.SObjectType).size());
        System.assertEquals(1, result.getUndeleteResults(Account.SObjectType).size());
        System.assertEquals(1, result.getEmptyRecycleBinResults(Account.SObjectType).size());
    }

    @IsTest
    static void test_partial_relationship() {
        List<Account> accounts = new List<Account>();
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 10; ++i) {
            accounts.add(new Account(
                Id = DBContextMock.getFakeId(Account.SObjectType)
            ));
            for (Integer j = 0; j < 2; ++j) {
                contacts.add(new Contact(
                    Account = accounts[i]
                ));
            }
        }

        IDBContext dbcontext = new DBContext();
        dbcontext.insertObjects(contacts, false);
        dbcontext.commitObjects();

        for (Integer i = 0; i < 10; ++i) {
            for (Integer j = 0; j < 2; ++j) {
                System.assertEquals(accounts[i].Id, contacts[i * 2 + j].AccountId);
            }
        }
    }

    @IsTest
    static void test_partial_relationship_20() {
        Integer numberOfRecords = 20;
        List<Account> accounts = new List<Account>();
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < numberOfRecords/2; ++i) {
            accounts.add(new Account(
                Id = DBContextMock.getFakeId(Account.SObjectType)
            ));
            contacts.add(new Contact(
                Account = accounts[i]
            ));
        }

        IDBContext dbcontext = new DBContext();
        dbcontext.updateObjects(accounts, false);
        dbcontext.insertObjects(contacts, false);
        dbcontext.commitObjects();

        System.assertEquals(numberOfRecords + 1, Limits.getDmlRows());
        for (Integer i = 0; i < numberOfRecords/2; ++i) {
            System.assertEquals(accounts[i].Id, contacts[i].AccountId);
        }
    }

    @IsTest
    static void test_partial_hierarchy() {
        List<Case> parentCases = new List<Case>();
        List<Case> childCases = new List<Case>();
        for (Integer i = 0; i < 10; ++i) {
            parentCases.add(new Case());
            childCases.add(new Case(
                parent = parentCases[i]
            ));
        }

        IDBContext dbcontext = new DBContext();
        dbcontext.insertObjects(childCases, false);
        dbcontext.commitObjects();

        for (Integer i = 0; i < 10; ++i) {
            parentCases[i].Id = DBContextMock.getFakeId(Case.SObjectType);
        }

        dbcontext.insertObjects(childCases, false);
        dbcontext.commitObjects();

        for (Integer i = 0; i < 10; ++i) {
            System.assertEquals(parentCases[i].Id, childCases[i].ParentId);
        }
    }

    @IsTest
    static void test_no_assertions() {
        new DMLResult(null, true, true);
        IDBContext dbcontext = new DBContext();
        IDBResult dbresult = dbcontext.commitObjects();
        dbresult.rollback();
    }

    @IsTest
    static void test_mockup() {
        IDBContext dbcontext = new DBContextMock();
        dbcontext.insertObjects(new List<Account> { new Account() }, false);
        dbcontext.upsertObjects(new List<Account> { new Account() }, false);
        dbcontext.updateObjects(new List<Account> { new Account(Id = DBContextMock.getFakeId(Account.SObjectType)) }, false);
        dbcontext.deleteObjects(new List<Account> { new Account(Id = DBContextMock.getFakeId(Account.SObjectType)) }, false);
        dbcontext.undeleteObjects(new List<Account> { new Account(Id = DBContextMock.getFakeId(Account.SObjectType)) }, false);
        dbcontext.emptyRecycleBin(new List<Account> { new Account(Id = DBContextMock.getFakeId(Account.SObjectType)) }, false);
        dbcontext.deleteObjects(new List<Id> { DBContextMock.getFakeId(Account.SObjectType) }, false);
        dbcontext.undeleteObjects(new List<Id> { DBContextMock.getFakeId(Account.SObjectType) }, false);
        dbcontext.emptyRecycleBin(new List<Id> { DBContextMock.getFakeId(Account.SObjectType) }, false);
        IDBResult result = dbcontext.commitObjects();

        System.assertEquals(0, result.getInsertErrors(Account.SObjectType).size());
        System.assertEquals(0, result.getUpdateErrors(Account.SObjectType).size());
        System.assertEquals(0, result.getUpsertErrors(Account.SObjectType).size());
        System.assertEquals(0, result.getDeleteErrors(Account.SObjectType).size());
        System.assertEquals(0, result.getUndeleteErrors(Account.SObjectType).size());
        System.assertEquals(0, result.getEmptyRecycleBinErrors(Account.SObjectType).size());

        System.assertEquals(1, result.getInsertResults(Account.SObjectType).size());
        System.assertEquals(1, result.getUpdateResults(Account.SObjectType).size());
        System.assertEquals(1, result.getUpsertResults(Account.SObjectType).size());
        System.assertEquals(2, result.getDeleteResults(Account.SObjectType).size());
        System.assertEquals(2, result.getUndeleteResults(Account.SObjectType).size());
        System.assertEquals(2, result.getEmptyRecycleBinResults(Account.SObjectType).size());
    }

    @IsTest
    static void test_mockup_phantom_update() {
        IDBContext dbcontext = new DBContextMock();

        List<Contact> contacts = new List<Contact> {
            new Contact(LastName = 'Name 0'),
            new Contact(LastName = 'Name 1'),
            new Contact(LastName = 'Name 2')
        };
        dbcontext.insertObjects(contacts);


        List<Account> accounts = new List<Account> {
            new Account(Name = 'Name 0'),
            new Account(Name = 'Name 1'),
            new Account(Name = 'Name 2')
        };
        dbcontext.insertObjects(accounts);

        for (Integer i = 0; i < accounts.size(); i++) {
            contacts[i].Account = accounts[i];
        }
        dbcontext.updateObjects(contacts);

        IDBResult result = dbcontext.commitObjects();

        for (Integer i = 0; i < accounts.size(); i++) {
            Account account = accounts[i];
            Contact contact = contacts[i];

            System.assertEquals(account.Id, contact.AccountId);
        }
    }

    @IsTest
    static void test_mockup_child_context() {
        IDBContext dbcontext = new DBContextMock();

        // pretend contact service created some contacts;
        IDBContext dbcontext_child1 = dbcontext.create();
        List<Contact> contacts = new List<Contact> {
            new Contact(LastName = 'Name 0'),
            new Contact(LastName = 'Name 1'),
            new Contact(LastName = 'Name 2')
        };
        dbcontext_child1.insertObjects(contacts);

        // pretend account service created some accounts;
        IDBContext dbcontext_child2 = dbcontext.create();
        List<Account> accounts = new List<Account> {
            new Account(Name = 'Name 0'),
            new Account(Name = 'Name 1'),
            new Account(Name = 'Name 2')
        };
        dbcontext_child2.insertObjects(accounts);

        // bind the relationship in the main context;
        for (Integer i = 0; i < accounts.size(); i++) {
            contacts[i].Account = accounts[i];
        }
        dbcontext.updateObjects(contacts);

        IDBResult result = dbcontext.commitObjects();

        for (Integer i = 0; i < accounts.size(); i++) {
            Account account = accounts[i];
            Contact contact = contacts[i];

            system.assertNotEquals(null, account.Id);
            system.assertNotEquals(null, contact.AccountId);
            System.assertEquals(account.Id, contact.AccountId);
        }
    }
    @IsTest
    static void test_mockup_child_context2() {
        IDBContext dbcontext = new DBContextMock();

        // pretend contact service created some contacts;
        IDBContext dbcontext_child1 = dbcontext.create();
        List<Contact> contacts = new List<Contact> {
            new Contact(LastName = 'Name 0'),
            new Contact(LastName = 'Name 1'),
            new Contact(LastName = 'Name 2')
        };
        dbcontext_child1.insertObjects(contacts);

        // pretend account service created some accounts;
        IDBContext dbcontext_child2 = dbcontext_child1.create();
        List<Account> accounts = new List<Account> {
            new Account(Name = 'Name 0'),
            new Account(Name = 'Name 1'),
            new Account(Name = 'Name 2')
        };
        dbcontext_child2.insertObjects(accounts);

        // bind the relationship in the main context;
        for (Integer i = 0; i < accounts.size(); i++) {
            contacts[i].Account = accounts[i];
        }
        dbcontext.updateObjects(contacts);

        IDBResult result = dbcontext.commitObjects();

        for (Integer i = 0; i < accounts.size(); i++) {
            Account account = accounts[i];
            Contact contact = contacts[i];

            system.assertNotEquals(null, account.Id);
            system.assertNotEquals(null, contact.AccountId);
            System.assertEquals(account.Id, contact.AccountId);
        }
    }

    @IsTest
    static void test_mockup_fake_ids() {
        IDBContext dbcontext = new DBContextMock();

        List<Account> accounts = new List<Account> {
            new Account(Name = 'Name 0'),
            new Account(Name = 'Name 1'),
            new Account(Name = 'Name 2')
        };
        dbcontext.insertObjects(accounts);
        IDBResult result = dbcontext.commitObjects();

        Map<Id, Account> accountMap = new Map<Id, Account>(accounts);
        for (Integer i = 0; i < accounts.size(); i++) {
            Account account = accounts[i];

            System.assertEquals(account.Name, 'Name ' + i);
            System.assertEquals(account.Name, accountMap.get(account.Id).Name);
        }
    }

    @IsTest
    static void test_mockup_fake_ids2() {
        Id accId1 = DBContextMock.getFakeId(Account.SObjectType);
        Id conId1 = DBContextMock.getFakeId(Contact.SObjectType);
        Id accId2 = DBContextMock.getFakeId(Account.SObjectType);
        Id conId2 = DBContextMock.getFakeId(Contact.SObjectType);
        Id accId3 = DBContextMock.getFakeId(Account.SObjectType);
        Id conId3 = DBContextMock.getFakeId(Contact.SObjectType);

        System.assertEquals('000zzzz00001', String.valueOf(accId1).substring(3, 15));
        System.assertEquals('000zzzz00002', String.valueOf(accId2).substring(3, 15));
        System.assertEquals('000zzzz00003', String.valueOf(accId3).substring(3, 15));
        System.assertEquals('000zzzz00001', String.valueOf(conId1).substring(3, 15));
        System.assertEquals('000zzzz00002', String.valueOf(conId2).substring(3, 15));
        System.assertEquals('000zzzz00003', String.valueOf(conId3).substring(3, 15));
    }
}
