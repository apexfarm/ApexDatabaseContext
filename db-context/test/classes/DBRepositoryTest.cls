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
public with sharing class DBRepositoryTest {
    @IsTest
    static void test_empty_repo() {
        IDBContext dbcontext = new DBContextMock();
        IDBRepository accountRepository = new DBRepository()
            .config(dbcontext).config(Account.SObjectType);
        IDBRepository contactRepository = new DBRepository()
            .config(dbcontext).config(Contact.SObjectType);

        accountRepository.save();
        contactRepository.save(false);

        IDBResult dbresult = dbcontext.commitObjects();
        dbresult.rollback();
    }

    @IsTest
    static void test_null_objects() {
        IDBContext dbcontext = new DBContextMock();
        IDBRepository accountRepository = new DBRepository().config(dbcontext);

        accountRepository.create(null);
        accountRepository.modify(null);
        accountRepository.modify(null, null);
        accountRepository.modify(new Account(), null);
        accountRepository.remove(null);

        accountRepository.save(false);
        IDBResult result = dbcontext.commitObjects();

        System.assertEquals(0, result.getInsertErrors(Account.SObjectType).size());
        System.assertEquals(0, result.getUpdateErrors(Account.SObjectType).size());
        System.assertEquals(0, result.getDeleteErrors(Contact.SObjectType).size());
        System.assertEquals(0, result.getInsertResults(Account.SObjectType).size());
        System.assertEquals(0, result.getUpdateResults(Account.SObjectType).size());
        System.assertEquals(0, result.getDeleteResults(Contact.SObjectType).size());
        System.assertEquals(0, result.getUpsertResults(Account.SObjectType).size());
        System.assertEquals(0, result.getUndeleteResults(Account.SObjectType).size());
        System.assertEquals(0, result.getEmptyRecycleBinResults(Contact.SObjectType).size());
    }

    @IsTest
    static void test_fetch_query() {
        IDBContext dbcontext = new DBContext();
        IDBRepository accountRepository = new DBRepository()
            .config(dbcontext).config(Account.SObjectType);
        IDBRepository contactRepository = new DBRepository()
            .config(dbcontext).config(Contact.SObjectType);

        List<SObject> accounts;
        accounts = accountRepository.fetch(null);
        accounts = accountRepository.fetch('SELECT Id FROM Account LIMIT 10');

        List<SObject> contacts;
        contacts = contactRepository.fetch(null);
        contacts = contactRepository.fetch('SELECT Id FROM Contact LIMIT 10');

        accountRepository.save();
        contactRepository.save(false);

        dbcontext.commitObjects();
    }

    @IsTest
    static void test_insert() {
        IDBContext dbcontext = new DBContext();
        IDBRepository accountRepository = new DBRepository()
            .config(dbcontext).config(Account.SObjectType);
        IDBRepository contactRepository = new DBRepository()
            .config(dbcontext).config(Contact.SObjectType);

        for (Integer i = 0; i < 10; i++) {
            accountRepository.create(new Account());

            contactRepository.create(new Contact());

            contactRepository.remove(new Contact(
                Id = DBContextMock.getFakeId(Contact.SObjectType)
            ));
        }

        accountRepository.save(false);
        Database.DMLOptions dmlOptions = new Database.DMLOptions();
        contactRepository.save(dmlOptions);

        IDBResult result = dbcontext.commitObjects();

        System.assertEquals(10, result.getInsertErrors(Account.SObjectType).size());
        System.assertEquals(10, result.getInsertErrors(Contact.SObjectType).size());
        System.assertEquals(10, result.getDeleteErrors(Contact.SObjectType).size());
        System.assertEquals(10, result.getInsertResults(Account.SObjectType).size());
        System.assertEquals(10, result.getInsertResults(Contact.SObjectType).size());
        System.assertEquals(10, result.getDeleteResults(Contact.SObjectType).size());
    }

    @IsTest
    static void test_insert_relate() {
        IDBContext dbcontext = new DBContextMock();
        IDBRepository accountRepository = new DBRepository()
            .config(dbcontext).config(Account.SObjectType);
        IDBRepository contactRepository = new DBRepository()
            .config(dbcontext).config(Contact.SObjectType);

        List<Account> accounts = new List<Account>();
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 10; i++) {
            Account acc = (Account)accountRepository.create(new Account());
            accounts.add(acc);

            Contact con = (Contact)contactRepository.create(new Contact());
            contactRepository.relate(con, Contact.AccountId, acc);
            contacts.add(con);

            contactRepository.remove(new Contact(
                Id = DBContextMock.getFakeId(Contact.SObjectType)
            ));
        }

        accountRepository.save(false);
        Database.DMLOptions dmlOptions = new Database.DMLOptions();
        dmlOptions.optAllOrNone = false;
        contactRepository.save(dmlOptions);

        IDBResult result = dbcontext.commitObjects();

        System.assertEquals(0, result.getInsertErrors(Account.SObjectType).size());
        System.assertEquals(0, result.getInsertErrors(Contact.SObjectType).size());
        System.assertEquals(0, result.getDeleteErrors(Contact.SObjectType).size());
        System.assertEquals(10, result.getInsertResults(Account.SObjectType).size());
        System.assertEquals(10, result.getInsertResults(Contact.SObjectType).size());
        System.assertEquals(10, result.getDeleteResults(Contact.SObjectType).size());

        for (Integer i = 0; i < 10; i++) {
            System.assertEquals(accounts[i].Id, contacts[i].AccountId);
        }
    }

    @IsTest
    static void test_update() {
        IDBContext dbcontext = new DBContextMock();
        IDBRepository accountRepository = new DBRepository()
            .config(dbcontext).config(Account.SObjectType);
        IDBRepository contactRepository = new DBRepository()
            .config(dbcontext).config(Contact.SObjectType);

        List<Account> accounts = new List<Account>();
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 10; i++) {
            Account acc = (Account)accountRepository.modify(new Account(
                Id = DBContextMock.getFakeId(Account.SObjectType))
            );
            accounts.add(acc);

            Contact con = (Contact)contactRepository.modify(new Contact(
                Id = DBContextMock.getFakeId(Contact.SObjectType),
                Account = acc
            ));
            contacts.add(con);

            contactRepository.remove(new Contact(
                Id = DBContextMock.getFakeId(Contact.SObjectType)
            ));
        }

        accountRepository.save(false);
        Database.DMLOptions dmlOptions = new Database.DMLOptions();
        dmlOptions.optAllOrNone = false;
        contactRepository.save(dmlOptions);

        IDBResult result = dbcontext.commitObjects();

        System.assertEquals(0, result.getUpdateErrors(Account.SObjectType).size());
        System.assertEquals(0, result.getUpdateErrors(Contact.SObjectType).size());
        System.assertEquals(0, result.getDeleteErrors(Contact.SObjectType).size());
        System.assertEquals(10, result.getUpdateResults(Account.SObjectType).size());
        System.assertEquals(10, result.getUpdateResults(Contact.SObjectType).size());
        System.assertEquals(10, result.getDeleteResults(Contact.SObjectType).size());
        for (Integer i = 0; i < 10; i++) {
            System.assertEquals(accounts[i].Id, contacts[i].AccountId);
        }
    }

    @IsTest
    static void test_update_relate() {
        IDBContext dbcontext = new DBContextMock();
        IDBRepository accountRepository = new DBRepository()
            .config(dbcontext).config(Account.SObjectType);
        IDBRepository contactRepository = new DBRepository()
            .config(dbcontext).config(Contact.SObjectType);

        List<Account> accounts = new List<Account>();
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 10; i++) {
            Account acc = (Account)accountRepository.modify(new Account(
                Id = DBContextMock.getFakeId(Account.SObjectType)
            ));
            accounts.add(acc);

            Contact con = (Contact)contactRepository.modify(new Contact(
                Id = DBContextMock.getFakeId(Contact.SObjectType)
            ));
            contactRepository.relate(con, Contact.AccountId, acc);
            contacts.add(con);

            contactRepository.remove(new Contact(
                Id = DBContextMock.getFakeId(Contact.SObjectType)
            ));
        }

        accountRepository.save(false);
        Database.DMLOptions dmlOptions = new Database.DMLOptions();
        dmlOptions.optAllOrNone = false;
        contactRepository.save(dmlOptions);

        IDBResult result = dbcontext.commitObjects();

        System.assertEquals(0, result.getUpdateErrors(Account.SObjectType).size());
        System.assertEquals(0, result.getUpdateErrors(Contact.SObjectType).size());
        System.assertEquals(0, result.getDeleteErrors(Contact.SObjectType).size());
        System.assertEquals(10, result.getUpdateResults(Account.SObjectType).size());
        System.assertEquals(10, result.getUpdateResults(Contact.SObjectType).size());
        System.assertEquals(10, result.getDeleteResults(Contact.SObjectType).size());

        for (Integer i = 0; i < 10; i++) {
            System.assertEquals(accounts[i].Id, contacts[i].AccountId);
        }
    }

    @IsTest
    static void test_update_multiple_time() {
        IDBContext dbcontext = new DBContextMock();
        IDBRepository accountRepository = new DBRepository()
            .config(dbcontext).config(Account.SObjectType);
        IDBRepository contactRepository = new DBRepository()
            .config(dbcontext).config(Contact.SObjectType);

        List<Account> accounts = new List<Account>();
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 10; i++) {
            Id accountId = DBContextMock.getFakeId(Account.SObjectType);
            accountRepository.modify(new Account(
                Id = accountId));
            Account acc = (Account)accountRepository.modify(new Account(
                Id = accountId, Name = 'Account Name'));
            accounts.add(acc);

            Id contactId = DBContextMock.getFakeId(Contact.SObjectType);
            contactRepository.modify(new Contact(
                Id = contactId,
                Account = acc
            ));
            Contact con = (Contact)contactRepository.modify(new Contact(
                Id = contactId, LastName = 'Last Name'));
            contacts.add(con);
        }
        accountRepository.save(false);
        contactRepository.save(false);

        IDBResult result = dbcontext.commitObjects();

        System.assertEquals(0, result.getUpdateErrors(Account.SObjectType).size());
        System.assertEquals(0, result.getUpdateErrors(Contact.SObjectType).size());
        System.assertEquals(10, result.getUpdateResults(Account.SObjectType).size());
        System.assertEquals(10, result.getUpdateResults(Contact.SObjectType).size());

        for (Integer i = 0; i < 10; i++) {
            System.assertEquals(accounts[i].Id, contacts[i].AccountId);
        }
    }

    @IsTest
    static void test_update_fields_multiple_time() {
        IDBContext dbcontext = new DBContextMock();
        IDBRepository accountRepository = new DBRepository()
            .config(dbcontext).config(Account.SObjectType);
        IDBRepository contactRepository = new DBRepository()
            .config(dbcontext).config(Contact.SObjectType);

        List<Account> accounts = new List<Account>();
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 10; i++) {
            Account acc = (Account)accountRepository.modify(new Account(
                Id = DBContextMock.getFakeId(Account.SObjectType)),
                new List<Schema.SObjectField>());
            accounts.add(acc);

            accountRepository.modify(
                new Account(Id = acc.Id, Name = 'Account Name'),
                new List<Schema.SObjectField> { Account.Name });

            Contact con = (Contact)contactRepository.modify(new Contact(
                Id = DBContextMock.getFakeId(Contact.SObjectType),
                Account = acc
            ), new List<Schema.SObjectField>());
            contacts.add(con);

            contactRepository.modify(
                new Contact(Id = con.Id, LastName = 'Last Name'),
                new List<Schema.SObjectField> { Contact.LastName });
        }
        accountRepository.save(false);
        contactRepository.save(false);

        IDBResult result = dbcontext.commitObjects();

        System.assertEquals(0, result.getUpdateErrors(Account.SObjectType).size());
        System.assertEquals(0, result.getUpdateErrors(Contact.SObjectType).size());
        System.assertEquals(10, result.getUpdateResults(Account.SObjectType).size());
        System.assertEquals(10, result.getUpdateResults(Contact.SObjectType).size());

        for (Integer i = 0; i < 10; i++) {
            System.assertEquals(accounts[i].Id, contacts[i].AccountId);
        }
    }

    @IsTest
    static void test_update_null_fields() {
        IDBContext dbcontext = new DBContextMock();
        IDBRepository accountRepository = new DBRepository().config(dbcontext);

        accountRepository.modify(new Account(Id = DBContextMock.getFakeId(Account.SObjectType)), null);

        accountRepository.save(false);
        IDBResult result = dbcontext.commitObjects();

        System.assertEquals(0, result.getUpdateErrors(Account.SObjectType).size());
        System.assertEquals(1, result.getUpdateResults(Account.SObjectType).size());
    }

    @IsTest
    static void test_delete() {
        IDBContext dbcontext = new DBContextMock();
        IDBRepository accountRepository = new DBRepository()
            .config(dbcontext).config(Account.SObjectType);
        IDBRepository contactRepository = new DBRepository()
            .config(dbcontext).config(Contact.SObjectType);

        for (Integer i = 0; i < 10; i++) {
            Account account = new Account(Id = DBContextMock.getFakeId(Account.SObjectType));
            accountRepository.remove(account);

            Contact contact = new Contact(Id = DBContextMock.getFakeId(Contact.SObjectType));
            contactRepository.remove(contact);
        }
        accountRepository.save(false);
        contactRepository.save(false);

        IDBResult result = dbcontext.commitObjects();

        System.assertEquals(0, result.getDeleteErrors(Account.SObjectType).size());
        System.assertEquals(0, result.getDeleteErrors(Contact.SObjectType).size());
        System.assertEquals(10, result.getDeleteResults(Account.SObjectType).size());
        System.assertEquals(10, result.getDeleteResults(Contact.SObjectType).size());
    }

    @IsTest
    static void text_mix_dmls() {
        IDBContext dbcontext = new DBContextMock();
        IDBRepository accountRepository = new DBRepository()
            .config(dbcontext).config(Account.SObjectType);
        IDBRepository contactRepository = new DBRepository()
            .config(dbcontext).config(Contact.SObjectType);

        List<Contact> contacts = new List<Contact> {
            new Contact(Id = DBContextMock.getFakeId(Contact.SObjectType)),
            new Contact(Id = DBContextMock.getFakeId(Contact.SObjectType)),
            new Contact(Id = DBContextMock.getFakeId(Contact.SObjectType)),
            new Contact(Id = DBContextMock.getFakeId(Contact.SObjectType)),
            new Contact(Id = DBContextMock.getFakeId(Contact.SObjectType)),
            new Contact(Id = DBContextMock.getFakeId(Contact.SObjectType)),
            new Contact(Id = DBContextMock.getFakeId(Contact.SObjectType)),
            new Contact(Id = DBContextMock.getFakeId(Contact.SObjectType)),
            new Contact(Id = DBContextMock.getFakeId(Contact.SObjectType)),
            new Contact(Id = DBContextMock.getFakeId(Contact.SObjectType))
        };
        List<Account> accounts = new List<Account>();

        for (Contact con : contacts) {
            con.FirstName = 'First Name';
            con.LastName = 'Last Name';
            contactRepository.modify(con, new List<Schema.SObjectField> {
                Contact.FirstName,
                Contact.LastName
            });

            Account acc = (Account)accountRepository.create(new Account(
                BillingCity = 'Dalian',
                BillingCountry = 'China'
            ));
            accounts.add(acc);

            contactRepository.modify(new Contact(
                    Id = con.Id,            // new contact will be merged into the repo
                    Account = acc           // new account without an Id yet
                ), new List<Schema.SObjectField> {
                    Contact.AccountId       // use Id field to indicate the above relationship
                });
        }

        // saving order matters
        accountRepository.save(false);      // allOrNone = true
        contactRepository.save(false);      // allOrNone = false

        IDBResult result = dbcontext.commitObjects();
        System.assertEquals(10, result.getInsertResults(Account.SObjectType).size());
        System.assertEquals(10, result.getUpdateResults(Contact.SObjectType).size());

        for (Integer i = 0; i < 10; i++) {
            System.assertEquals(accounts[i].Id, contacts[i].AccountId);
        }
    }
}
