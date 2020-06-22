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

        System.assertEquals(0, result.getResultsForInsert(Account.SObjectType).size());
        System.assertEquals(0, result.getResultsForUpdate(Account.SObjectType).size());
        System.assertEquals(0, result.getResultsForUpsert(Account.SObjectType).size());
        System.assertEquals(0, result.getResultsForDelete(Account.SObjectType).size());
        System.assertEquals(0, result.getResultsForUndelete(Account.SObjectType).size());
        System.assertEquals(0, result.getResultsForEmptyRecycleBin(Account.SObjectType).size());

        System.assertEquals(0, result.getErrorsForInsert(Account.SObjectType).size());
        System.assertEquals(0, result.getErrorsForUpdate(Account.SObjectType).size());
        System.assertEquals(0, result.getErrorsForUpsert(Account.SObjectType).size());
        System.assertEquals(0, result.getErrorsForDelete(Account.SObjectType).size());
        System.assertEquals(0, result.getErrorsForUndelete(Account.SObjectType).size());
        System.assertEquals(0, result.getErrorsForEmptyRecycleBin(Account.SObjectType).size());
    }

    @IsTest
    static void test_AllOrNone_null_list() {
        IDBContext dbcontext = new DBContext();
        dbcontext.insertObjects(null);
        dbcontext.upsertObjects(null);
        dbcontext.updateObjects(null);
        dbcontext.deleteObjects(null);
        dbcontext.undeleteObjects(null);
        dbcontext.emptyRecycleBin(null);
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
        IDBResult result = dbcontext.commitObjects();

        System.assertEquals(0, result.getErrorsForInsert(Account.SObjectType).size());
        System.assertEquals(0, result.getErrorsForUpdate(Account.SObjectType).size());
        System.assertEquals(0, result.getErrorsForUpsert(Account.SObjectType).size());
        System.assertEquals(0, result.getErrorsForDelete(Account.SObjectType).size());
        System.assertEquals(0, result.getErrorsForUndelete(Account.SObjectType).size());
        System.assertEquals(0, result.getErrorsForEmptyRecycleBin(Account.SObjectType).size());
    }

    @IsTest
    static void test_AllOrNone_exception() {
        IDBContext dbcontext = new DBContext();
        dbcontext.insertObjects(new List<Account> { new Account() });
        Boolean hasException = false;
        try {
            dbcontext.commitObjects();
        } catch(Exception ex) {
            hasException = true;
        }
        System.assertEquals(true, hasException);
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
        IDBResult result = dbcontext.commitObjects();

        System.assertEquals(0, result.getErrorsForInsert(Account.SObjectType).size());
        System.assertEquals(0, result.getErrorsForUpdate(Account.SObjectType).size());
        System.assertEquals(0, result.getErrorsForUpsert(Account.SObjectType).size());
        System.assertEquals(0, result.getErrorsForDelete(Account.SObjectType).size());
        System.assertEquals(0, result.getErrorsForUndelete(Account.SObjectType).size());
        System.assertEquals(0, result.getErrorsForEmptyRecycleBin(Account.SObjectType).size());
    }

    @IsTest
    static void test_partial_one_object_list() {
        IDBContext dbcontext = new DBContext();
        dbcontext.insertObjects(new List<Account> { new Account() }, false);
        dbcontext.upsertObjects(new List<Account> { new Account() }, false);
        dbcontext.updateObjects(new List<Account> { new Account(Id = DBContextMockup.getFakeId(Account.SObjectType)) }, false);
        dbcontext.deleteObjects(new List<Account> { new Account(Id = DBContextMockup.getFakeId(Account.SObjectType)) }, false);
        dbcontext.undeleteObjects(new List<Account> { new Account(Id = DBContextMockup.getFakeId(Account.SObjectType)) }, false);
        dbcontext.emptyRecycleBin(new List<Account> { new Account(Id = DBContextMockup.getFakeId(Account.SObjectType)) }, false);
        dbcontext.emptyRecycleBin(new List<Account> { new Account(Id = DBContextMockup.getFakeId(Account.SObjectType)) }, true);
        IDBResult result = dbcontext.commitObjects();

        System.assertEquals(1, result.getErrorsForInsert(Account.SObjectType).size());
        System.assertEquals(1, result.getErrorsForUpdate(Account.SObjectType).size());
        System.assertEquals(1, result.getErrorsForUpsert(Account.SObjectType).size());
        System.assertEquals(1, result.getErrorsForDelete(Account.SObjectType).size());
        System.assertEquals(1, result.getErrorsForUndelete(Account.SObjectType).size());
        System.assertEquals(1, result.getErrorsForEmptyRecycleBin(Account.SObjectType).size());

        System.assertEquals(1, result.getResultsForInsert(Account.SObjectType).size());
        System.assertEquals(1, result.getResultsForUpdate(Account.SObjectType).size());
        System.assertEquals(1, result.getResultsForUpsert(Account.SObjectType).size());
        System.assertEquals(1, result.getResultsForDelete(Account.SObjectType).size());
        System.assertEquals(1, result.getResultsForUndelete(Account.SObjectType).size());
        System.assertEquals(1, result.getResultsForEmptyRecycleBin(Account.SObjectType).size());
    }

    @IsTest
    static void test_partial_one_object_list_child_context() {
        IDBContext dbcontext = new DBContext();
        IDBContext childContext1 = dbcontext.create();
        IDBContext childContext2 = dbcontext.create();
        childContext1.insertObjects(new List<Account> { new Account() }, false);
        childContext2.upsertObjects(new List<Account> { new Account() }, false);
        childContext1.updateObjects(new List<Account> { new Account(Id = DBContextMockup.getFakeId(Account.SObjectType)) }, false);
        childContext2.deleteObjects(new List<Account> { new Account(Id = DBContextMockup.getFakeId(Account.SObjectType)) }, false);
        childContext1.undeleteObjects(new List<Account> { new Account(Id = DBContextMockup.getFakeId(Account.SObjectType)) }, false);
        childContext2.emptyRecycleBin(new List<Account> { new Account(Id = DBContextMockup.getFakeId(Account.SObjectType)) }, false);
        childContext1.emptyRecycleBin(new List<Account> { new Account(Id = DBContextMockup.getFakeId(Account.SObjectType)) }, true);
        IDBResult result = dbcontext.commitObjects();

        System.assertEquals(1, result.getErrorsForInsert(Account.SObjectType).size());
        System.assertEquals(1, result.getErrorsForUpdate(Account.SObjectType).size());
        System.assertEquals(1, result.getErrorsForUpsert(Account.SObjectType).size());
        System.assertEquals(1, result.getErrorsForDelete(Account.SObjectType).size());
        System.assertEquals(1, result.getErrorsForUndelete(Account.SObjectType).size());
        System.assertEquals(1, result.getErrorsForEmptyRecycleBin(Account.SObjectType).size());

        System.assertEquals(1, result.getResultsForInsert(Account.SObjectType).size());
        System.assertEquals(1, result.getResultsForUpdate(Account.SObjectType).size());
        System.assertEquals(1, result.getResultsForUpsert(Account.SObjectType).size());
        System.assertEquals(1, result.getResultsForDelete(Account.SObjectType).size());
        System.assertEquals(1, result.getResultsForUndelete(Account.SObjectType).size());
        System.assertEquals(1, result.getResultsForEmptyRecycleBin(Account.SObjectType).size());
    }

    @IsTest
    static void test_partial_relationship() {
        List<Account> accounts = new List<Account>();
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 10; ++i) {
            accounts.add(new Account(
                Id = DBContextMockup.getFakeId(Account.SObjectType)
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
                Id = DBContextMockup.getFakeId(Account.SObjectType)
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
            parentCases[i].Id = DBContextMockup.getFakeId(Case.SObjectType);
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
    }

    @IsTest
    static void test_mockup() {
        IDBContext dbcontext = new DBContextMockup();
        dbcontext.insertObjects(new List<Account> { new Account() }, false);
        dbcontext.upsertObjects(new List<Account> { new Account() }, false);
        dbcontext.updateObjects(new List<Account> { new Account(Id = DBContextMockup.getFakeId(Account.SObjectType)) }, false);
        dbcontext.deleteObjects(new List<Account> { new Account(Id = DBContextMockup.getFakeId(Account.SObjectType)) }, false);
        dbcontext.undeleteObjects(new List<Account> { new Account(Id = DBContextMockup.getFakeId(Account.SObjectType)) }, false);
        dbcontext.emptyRecycleBin(new List<Account> { new Account(Id = DBContextMockup.getFakeId(Account.SObjectType)) }, false);
        IDBResult result = dbcontext.commitObjects();

        System.assertEquals(0, result.getErrorsForInsert(Account.SObjectType).size());
        System.assertEquals(0, result.getErrorsForUpdate(Account.SObjectType).size());
        System.assertEquals(0, result.getErrorsForUpsert(Account.SObjectType).size());
        System.assertEquals(0, result.getErrorsForDelete(Account.SObjectType).size());
        System.assertEquals(0, result.getErrorsForUndelete(Account.SObjectType).size());
        System.assertEquals(0, result.getErrorsForEmptyRecycleBin(Account.SObjectType).size());

        System.assertEquals(1, result.getResultsForInsert(Account.SObjectType).size());
        System.assertEquals(1, result.getResultsForUpdate(Account.SObjectType).size());
        System.assertEquals(1, result.getResultsForUpsert(Account.SObjectType).size());
        System.assertEquals(1, result.getResultsForDelete(Account.SObjectType).size());
        System.assertEquals(1, result.getResultsForUndelete(Account.SObjectType).size());
        System.assertEquals(1, result.getResultsForEmptyRecycleBin(Account.SObjectType).size());
    }

    @IsTest
    static void test_mockup_phantom_update() {
        IDBContext dbcontext = new DBContextMockup();

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
        IDBContext dbcontext = new DBContextMockup();

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
        IDBContext dbcontext = new DBContextMockup();

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
        IDBContext dbcontext = new DBContextMockup();

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
        Id accId1 = DBContextMockup.getFakeId(Account.SObjectType);
        Id conId1 = DBContextMockup.getFakeId(Contact.SObjectType);
        Id accId2 = DBContextMockup.getFakeId(Account.SObjectType);
        Id conId2 = DBContextMockup.getFakeId(Contact.SObjectType);
        Id accId3 = DBContextMockup.getFakeId(Account.SObjectType);
        Id conId3 = DBContextMockup.getFakeId(Contact.SObjectType);

        System.assertEquals('000zzzz00001', String.valueOf(accId1).substring(3, 15));
        System.assertEquals('000zzzz00002', String.valueOf(accId2).substring(3, 15));
        System.assertEquals('000zzzz00003', String.valueOf(accId3).substring(3, 15));
        System.assertEquals('000zzzz00001', String.valueOf(conId1).substring(3, 15));
        System.assertEquals('000zzzz00002', String.valueOf(conId2).substring(3, 15));
        System.assertEquals('000zzzz00003', String.valueOf(conId3).substring(3, 15));
    }
}
