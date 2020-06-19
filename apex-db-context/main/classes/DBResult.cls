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

public without sharing class DBResult implements IDBResult {
    public Map<Schema.SObjectType, List<Database.SaveResult>> insertResults { get; set; }
    public Map<Schema.SObjectType, List<Database.SaveResult>> updateResults { get; set; }
    public Map<Schema.SObjectType, List<Database.UpsertResult>> upsertResults { get; set; }
    public Map<Schema.SObjectType, List<Database.DeleteResult>> deleteResults { get; set; }
    public Map<Schema.SObjectType, List<Database.UndeleteResult>> undeleteResults { get; set; }
    public Map<Schema.SObjectType, List<Database.EmptyRecycleBinResult>> emptyRecycleBinResults { get; set; }

    {
        insertResults = new Map<Schema.SObjectType, List<Database.SaveResult>>();
        updateResults = new Map<Schema.SObjectType, List<Database.SaveResult>>();
        upsertResults = new Map<Schema.SObjectType, List<Database.UpsertResult>>();
        deleteResults = new Map<Schema.SObjectType, List<Database.DeleteResult>>();
        undeleteResults = new Map<Schema.SObjectType, List<Database.UndeleteResult>>();
        emptyRecycleBinResults = new Map<Schema.SObjectType, List<Database.EmptyRecycleBinResult>>();
    }

    public List<DMLResult> getErrorsForInsert(Schema.SObjectType objectType) {
        List<DMLResult> dmlResults = new List<DMLResult>();

        if (this.insertResults.containsKey(objectType)) {
            for (Database.SaveResult result : this.insertResults.get(objectType)) {
                if(!result.isSuccess()) {
                    dmlResults.add(new DMLResult(result, true));
                }
            }
        }
        return dmlResults;
    }

    public List<DMLResult> getErrorsForUpdate(Schema.SObjectType objectType) {
        List<DMLResult> dmlResults = new List<DMLResult>();

        if (this.updateResults.containsKey(objectType)) {
            for (Database.SaveResult result : this.updateResults.get(objectType)) {
                if(!result.isSuccess()) {
                    dmlResults.add(new DMLResult(result, true));
                }
            }
        }
        return dmlResults;
    }

    public List<DMLResult> getErrorsForUpsert(Schema.SObjectType objectType) {
        List<DMLResult> dmlResults = new List<DMLResult>();

        if (this.upsertResults.containsKey(objectType)) {
            for (Database.UpsertResult result : this.upsertResults.get(objectType)) {
                if(!result.isSuccess()) {
                    dmlResults.add(new DMLResult(result));
                }
            }
        }
        return dmlResults;
    }

    public List<DMLResult> getErrorsForDelete(Schema.SObjectType objectType) {
        List<DMLResult> dmlResults = new List<DMLResult>();

        if (this.deleteResults.containsKey(objectType)) {
            for (Database.DeleteResult result : this.deleteResults.get(objectType)) {
                if(!result.isSuccess()) {
                    dmlResults.add(new DMLResult(result));
                }
            }
        }
        return dmlResults;
    }

    public List<DMLResult> getErrorsForUndelete(Schema.SObjectType objectType) {
        List<DMLResult> dmlResults = new List<DMLResult>();

        if (this.undeleteResults.containsKey(objectType)) {
            for (Database.UndeleteResult result : this.undeleteResults.get(objectType)) {
                if(!result.isSuccess()) {
                    dmlResults.add(new DMLResult(result));
                }
            }
        }
        return dmlResults;
    }

    public List<DMLResult> getErrorsForEmptyRecycleBin(Schema.SObjectType objectType) {
        List<DMLResult> dmlResults = new List<DMLResult>();

        if (this.emptyRecycleBinResults.containsKey(objectType)) {
            for (Database.EmptyRecycleBinResult result : this.emptyRecycleBinResults.get(objectType)) {
                if(!result.isSuccess()) {
                    dmlResults.add(new DMLResult(result));
                }
            }
        }
        return dmlResults;
    }

    public List<DMLResult> getResultsForInsert(Schema.SObjectType objectType) {
        List<DMLResult> dmlResults = new List<DMLResult>();

        if (this.insertResults.containsKey(objectType)) {
            for (Database.SaveResult result : this.insertResults.get(objectType)) {
                dmlResults.add(new DMLResult(result, true));
            }
        }
        return dmlResults;
    }

    public List<DMLResult> getResultsForUpdate(Schema.SObjectType objectType) {
        List<DMLResult> dmlResults = new List<DMLResult>();

        if (this.updateResults.containsKey(objectType)) {
            for (Database.SaveResult result : this.updateResults.get(objectType)) {
                dmlResults.add(new DMLResult(result, false));
            }
        }
        return dmlResults;
    }

    public List<DMLResult> getResultsForUpsert(Schema.SObjectType objectType) {
        List<DMLResult> dmlResults = new List<DMLResult>();

        if (this.upsertResults.containsKey(objectType)) {
            for (Database.UpsertResult result : this.upsertResults.get(objectType)) {
                dmlResults.add(new DMLResult(result));
            }
        }
        return dmlResults;
    }

    public List<DMLResult> getResultsForDelete(Schema.SObjectType objectType) {
        List<DMLResult> dmlResults = new List<DMLResult>();

        if (this.deleteResults.containsKey(objectType)) {
            for (Database.DeleteResult result : this.deleteResults.get(objectType)) {
                dmlResults.add(new DMLResult(result));
            }
        }
        return dmlResults;
    }

    public List<DMLResult> getResultsForUndelete(Schema.SObjectType objectType) {
        List<DMLResult> dmlResults = new List<DMLResult>();

        if (this.undeleteResults.containsKey(objectType)) {
            for (Database.UndeleteResult result : this.undeleteResults.get(objectType)) {
                dmlResults.add(new DMLResult(result));
            }
        }
        return dmlResults;
    }

    public List<DMLResult> getResultsForEmptyRecycleBin(Schema.SObjectType objectType) {
        List<DMLResult> dmlResults = new List<DMLResult>();

        if (this.emptyRecycleBinResults.containsKey(objectType)) {
            for (Database.EmptyRecycleBinResult result : this.emptyRecycleBinResults.get(objectType)) {
                dmlResults.add(new DMLResult(result));
            }
        }
        return dmlResults;
    }
}