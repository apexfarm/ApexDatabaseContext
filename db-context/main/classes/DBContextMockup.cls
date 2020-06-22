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
public class DBContextMockup extends DBContext {
    static Map<Schema.SObjectType, Indexer> objectIdIndexes { get; set; }

    class Indexer {
        Integer i = 0;
    }

    static {
        objectIdIndexes = new Map<Schema.SObjectType, Indexer>();
    }

    public static String getFakeId(Schema.SObjectType objectType) {
        if (!objectIdIndexes.containsKey(objectType)) {
            objectIdIndexes.put(objectType, new Indexer());
        }

        Indexer idx = objectIdIndexes.get(objectType);
        idx.i++;
        return objectType.getDescribe().getKeyPrefix()
            + '000zzzz' // start from a large Id to avoid confliction during unit test.
            + String.valueOf(idx.i).leftPad(5, '0');
    }

    public override IDBResult commitObjects() {
        System.Savepoint sp = Database.setSavePoint();
        DBResultMockup result = new DBResultMockup();
		try {
            for (DMLDescriptor dmlDescriptor : dmlDescriptors) {
                if (dmlDescriptor.objects != null) {
                    switch on dmlDescriptor.dmlOperation {
                        when DO_INSERT, DO_UPSERT, DO_UPDATE {
                            dmlDescriptor.assignParentIds();
                            List<DMLResult> dmlResults = result.getDMLResults(
                                dmlDescriptor.objectType, dmlDescriptor.dmlOperation);
                            for (SObject obj : dmlDescriptor.objects) {
                                if (obj.Id == null) {
                                    obj.Id = getFakeId(dmlDescriptor.objectType);
                                    if (!dmlDescriptor.allOrNone) {
                                        dmlResults.add(new DMLResult(obj.Id, true, true));
                                    }
                                } else {
                                    if (!dmlDescriptor.allOrNone) {
                                        dmlResults.add(new DMLResult(obj.Id, true, false));
                                    }
                                }
                            }
                        }
                        when DO_DELETE, DO_UNDELETE, DO_EMPTY_RECYCLE_BIN {
                            if (!dmlDescriptor.allOrNone) {
                                List<DMLResult> dmlResults = result.getDMLResults(
                                    dmlDescriptor.objectType, dmlDescriptor.dmlOperation);
                                for (SObject obj : dmlDescriptor.objects) {
                                    dmlResults.add(new DMLResult(obj.Id, true, false));
                                }
                            }
                        }
                    }
                }
            }
            dmlDescriptors.clear();
		} catch (Exception ex) {
			Database.rollback(sp);
			throw ex;
		}
        return result;
    }

    public class DBResultMockup implements IDBResult {
        public Map<Schema.SObjectType, List<DMLResult>> insertResults { get; set; }
        public Map<Schema.SObjectType, List<DMLResult>> updateResults { get; set; }
        public Map<Schema.SObjectType, List<DMLResult>> upsertResults { get; set; }
        public Map<Schema.SObjectType, List<DMLResult>> deleteResults { get; set; }
        public Map<Schema.SObjectType, List<DMLResult>> undeleteResults { get; set; }
        public Map<Schema.SObjectType, List<DMLResult>> emptyRecycleBinResults { get; set; }

        {
            insertResults = new Map<Schema.SObjectType, List<DMLResult>>();
            updateResults = new Map<Schema.SObjectType, List<DMLResult>>();
            upsertResults = new Map<Schema.SObjectType, List<DMLResult>>();
            deleteResults = new Map<Schema.SObjectType, List<DMLResult>>();
            undeleteResults = new Map<Schema.SObjectType, List<DMLResult>>();
            emptyRecycleBinResults = new Map<Schema.SObjectType, List<DMLResult>>();
        }

        private List<DMLResult> getDMLResults(Schema.SObjectType objectType, DMLOperation dmlOperation) {
            List<DMLResult> dmlResults;
            switch on dmlOperation {
                when DO_INSERT {
                    if (!insertResults.containsKey(objectType)) {
                        insertResults.put(objectType, new List<DMLResult>());
                    }
                    dmlResults = insertResults.get(objectType);
                }
                when DO_UPSERT {
                    if (!upsertResults.containsKey(objectType)) {
                        upsertResults.put(objectType, new List<DMLResult>());
                    }
                    dmlResults = upsertResults.get(objectType);
                }
                when DO_UPDATE {
                    if (!updateResults.containsKey(objectType)) {
                        updateResults.put(objectType, new List<DMLResult>());
                    }
                    dmlResults = updateResults.get(objectType);
                }
                when DO_DELETE {
                    if (!deleteResults.containsKey(objectType)) {
                        deleteResults.put(objectType, new List<DMLResult>());
                    }
                    dmlResults = deleteResults.get(objectType);
                }
                when DO_UNDELETE {
                    if (!undeleteResults.containsKey(objectType)) {
                        undeleteResults.put(objectType, new List<DMLResult>());
                    }
                    dmlResults = undeleteResults.get(objectType);
                }
                when DO_EMPTY_RECYCLE_BIN {
                    if (!emptyRecycleBinResults.containsKey(objectType)) {
                        emptyRecycleBinResults.put(objectType, new List<DMLResult>());
                    }
                    dmlResults = emptyRecycleBinResults.get(objectType);
                }
            }
            return dmlResults;
        }

        public List<DMLResult> getErrorsForInsert(Schema.SObjectType objectType) {
            List<DMLResult> dmlResults = new List<DMLResult>();

            if (this.insertResults.containsKey(objectType)) {
                for (DMLResult result : this.insertResults.get(objectType)) {
                    if(!result.isSuccess) {
                        dmlResults.add(result);
                    }
                }
            }
            return dmlResults;
        }

        public List<DMLResult> getErrorsForUpdate(Schema.SObjectType objectType) {
            List<DMLResult> dmlResults = new List<DMLResult>();

            if (this.updateResults.containsKey(objectType)) {
                for (DMLResult result : this.updateResults.get(objectType)) {
                    if(!result.isSuccess) {
                        dmlResults.add(result);
                    }
                }
            }
            return dmlResults;
        }

        public List<DMLResult> getErrorsForUpsert(Schema.SObjectType objectType) {
            List<DMLResult> dmlResults = new List<DMLResult>();

            if (this.upsertResults.containsKey(objectType)) {
                for (DMLResult result : this.upsertResults.get(objectType)) {
                    if(!result.isSuccess) {
                        dmlResults.add(result);
                    }
                }
            }
            return dmlResults;
        }

        public List<DMLResult> getErrorsForDelete(Schema.SObjectType objectType) {
            List<DMLResult> dmlResults = new List<DMLResult>();

            if (this.deleteResults.containsKey(objectType)) {
                for (DMLResult result : this.deleteResults.get(objectType)) {
                    if(!result.isSuccess) {
                        dmlResults.add(result);
                    }
                }
            }
            return dmlResults;
        }

        public List<DMLResult> getErrorsForUndelete(Schema.SObjectType objectType) {
            List<DMLResult> dmlResults = new List<DMLResult>();

            if (this.undeleteResults.containsKey(objectType)) {
                for (DMLResult result : this.undeleteResults.get(objectType)) {
                    if(!result.isSuccess) {
                        dmlResults.add(result);
                    }
                }
            }
            return dmlResults;
        }

        public List<DMLResult> getErrorsForEmptyRecycleBin(Schema.SObjectType objectType) {
            List<DMLResult> dmlResults = new List<DMLResult>();

            if (this.emptyRecycleBinResults.containsKey(objectType)) {
                for (DMLResult result : this.emptyRecycleBinResults.get(objectType)) {
                    if(!result.isSuccess) {
                        dmlResults.add(result);
                    }
                }
            }
            return dmlResults;
        }

        public List<DMLResult> getResultsForInsert(Schema.SObjectType objectType) {
            return this.insertResults.get(objectType);
        }

        public List<DMLResult> getResultsForUpdate(Schema.SObjectType objectType) {
            return this.updateResults.get(objectType);
        }

        public List<DMLResult> getResultsForUpsert(Schema.SObjectType objectType) {
            return this.upsertResults.get(objectType);
        }

        public List<DMLResult> getResultsForDelete(Schema.SObjectType objectType) {
            return this.deleteResults.get(objectType);
        }

        public List<DMLResult> getResultsForUndelete(Schema.SObjectType objectType) {
            return this.undeleteResults.get(objectType);
        }

        public List<DMLResult> getResultsForEmptyRecycleBin(Schema.SObjectType objectType) {
            return this.emptyRecycleBinResults.get(objectType);
        }
    }
}