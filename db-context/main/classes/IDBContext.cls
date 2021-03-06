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

public interface IDBContext {
    IDBContext create();

    void insertObjects(List<SObject> objects);
    void insertObjects(List<SObject> objects, Boolean allOrNone);
    void insertObjects(List<SObject> objects, Database.DMLOptions dmlOptions);
    void upsertObjects(List<SObject> objects);
    void upsertObjects(List<SObject> objects, Boolean allOrNone);
    void updateObjects(List<SObject> objects);
    void updateObjects(List<SObject> objects, Boolean allOrNone);
    void updateObjects(List<SObject> objects, Database.DMLOptions dmlOptions);
    void deleteObjects(List<SObject> objects);
    void deleteObjects(List<SObject> objects, Boolean allOrNone);
    void deleteObjects(List<Id> objectIds);
    void deleteObjects(List<Id> objectIds, Boolean allOrNone);
    void undeleteObjects(List<SObject> objects);
    void undeleteObjects(List<SObject> objects, Boolean allOrNone);
    void undeleteObjects(List<Id> objectIds);
    void undeleteObjects(List<Id> objectIds, Boolean allOrNone);
    void emptyRecycleBin(List<SObject> objects);
    void emptyRecycleBin(List<SObject> objects, Boolean allOrNone);
    void emptyRecycleBin(List<Id> objectIds);
    void emptyRecycleBin(List<Id> objectIds, Boolean allOrNone);

    IDBResult commitObjects();
}