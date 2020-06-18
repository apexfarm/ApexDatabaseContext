/**
 * BSD 3-Clause License
 *
 * Copyright (c) 2020, Jianfeng Jin
 * https://github.com/apexfarm/ApexDatabaseContext
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

public with sharing class DatabaseContext implements IDatabaseContext {

    static Map<Schema.SObjectType, List<Schema.SObjectField>> relationshipFieldCache { get; set; }
    static Map<Schema.SObjectType, List<String>> relationshipNameCache { get; set; }

    List<ObjectDescriptor> objectDescriptors { get; set; }

    static {
        relationshipFieldCache = new Map<Schema.SObjectType, List<Schema.SObjectField>>();
        relationshipNameCache = new Map<Schema.SObjectType, List<String>>();
    }

    {
        objectDescriptors = new List<ObjectDescriptor>();
    }

    @TestVisible
    static void resolveRelationshipFields(Schema.SObjectType objectType) {
        if (!relationshipFieldCache.containsKey(objectType)) {
            List<Schema.SObjectField> relationshipFields = new List<Schema.SObjectField>();
            List<String> relationshipNames = new List<String>();

            for (Schema.SObjectField field : objectType.getDescribe().fields.getMap().values()) {
                String relationshipName = field.getDescribe().getRelationshipName();
                if (relationshipName != null) {
                    relationshipFields.add(field);
                    relationshipNames.add(relationshipName);
                }
            }
            relationshipFieldCache.put(objectType, relationshipFields);
            relationshipNameCache.put(objectType, relationshipNames);
        }
    }

    public void insertObjects(List<SObject> objects) {
        objectDescriptors.add(new ObjectDescriptor(OperationType.DO_INSERT, objects, true));
    }

    public void insertObjects(List<SObject> objects, Boolean allOrNone) {
        objectDescriptors.add(new ObjectDescriptor(OperationType.DO_INSERT, objects, allOrNone));
    }

    public void upsertObjects(List<SObject> objects) {
        objectDescriptors.add(new ObjectDescriptor(OperationType.DO_UPSERT, objects, true));
    }

    public void upsertObjects(List<SObject> objects, Boolean allOrNone) {
        objectDescriptors.add(new ObjectDescriptor(OperationType.DO_UPSERT, objects, allOrNone));
    }

    public void updateObjects(List<SObject> objects) {
        objectDescriptors.add(new ObjectDescriptor(OperationType.DO_UPDATE, objects, true));
    }

    public void updateObjects(List<SObject> objects, Boolean allOrNone) {
        objectDescriptors.add(new ObjectDescriptor(OperationType.DO_UPDATE, objects, allOrNone));
    }

    public void deleteObjects(List<SObject> objects) {
        objectDescriptors.add(new ObjectDescriptor(OperationType.DO_DELETE, objects, true));
    }

    public void deleteObjects(List<SObject> objects, Boolean allOrNone) {
        objectDescriptors.add(new ObjectDescriptor(OperationType.DO_DELETE, objects, allOrNone));
    }

    public void undeleteObjects(List<SObject> objects) {
        objectDescriptors.add(new ObjectDescriptor(OperationType.DO_UNDELETE, objects, true));
    }

    public void undeleteObjects(List<SObject> objects, Boolean allOrNone) {
        objectDescriptors.add(new ObjectDescriptor(OperationType.DO_UNDELETE, objects, allOrNone));
    }

    public void emptyRecycleBin(List<SObject> objects) {
        objectDescriptors.add(new ObjectDescriptor(OperationType.DO_EMPTY_RECYCLE_BIN, objects, true));
    }

    public IDatabaseCommitResult commitObjects() {
        System.Savepoint sp = Database.setSavePoint();
        CommitResult result = new CommitResult();
		try {
            for (ObjectDescriptor descriptor : objectDescriptors) {
                if (descriptor.objects != null) {
                    descriptor.assignParentIds(descriptor.objects);
                    switch on descriptor.operationType {
                        when DO_INSERT {
                            if (descriptor.allOrNone) {
                                insert descriptor.objects;
                            } else {
                                result.getResultsForInsert(descriptor.objectType).addAll(
                                    Database.insert(descriptor.objects, descriptor.allOrNone));
                            }
                        }
                        when DO_UPSERT {
                            if (descriptor.allOrNone) {
                                upsert descriptor.objects;
                            } else {
                                result.getResultsForUpsert(descriptor.objectType).addAll(
                                    Database.upsert(descriptor.objects, descriptor.allOrNone));
                            }
                        }
                        when DO_UPDATE {
                            if (descriptor.allOrNone) {
                                update descriptor.objects;
                            } else {
                                result.getResultsForUpdate(descriptor.objectType).addAll(
                                    Database.update(descriptor.objects, descriptor.allOrNone));
                            }
                        }
                        when DO_DELETE {
                            if (descriptor.allOrNone) {
                                delete descriptor.objects;
                            } else {
                                result.getResultsForDelete(descriptor.objectType).addAll(
                                    Database.delete(descriptor.objects, descriptor.allOrNone));
                            }
                        }
                        when DO_UNDELETE {
                            if (descriptor.allOrNone) {
                                undelete descriptor.objects;
                            } else {
                                result.getResultsForUndelete(descriptor.objectType).addAll(
                                    Database.undelete(descriptor.objects, descriptor.allOrNone));
                            }
                        }
                        when DO_EMPTY_RECYCLE_BIN {
                            if (!descriptor.objects.isEmpty()) {
                                result.getResultsForEmptyRecycleBin(descriptor.objectType).addAll(
                                    Database.emptyRecycleBin(descriptor.objects));
                            }
                        }
                    }
                }
            }
            objectDescriptors.clear();
		} catch (Exception ex) {
			Database.rollback(sp);
			throw ex;
		}
        return result;
    }

    public enum OperationType {
        DO_INSERT,
        DO_UPSERT,
        DO_UPDATE,
        DO_DELETE,
        DO_UNDELETE,
        DO_EMPTY_RECYCLE_BIN
    }

    class ObjectDescriptor {
        OperationType operationType { get; set; }
        Schema.SObjectType objectType { get; set; }
        Boolean allOrNone { get; set; }
        List<SObject> objects { get; set; }
        List<Schema.SObjectField> relationshipFields { get; set; }
        List<String> relationshipNames { get; set; }

        ObjectDescriptor(OperationType operationType, List<SObject> objects, Boolean allOrNone) {
            this.operationType = operationType;
            this.allOrNone = allOrNone;
            this.objects = objects;

            if (objects != null) {
                this.objectType = objects.getSObjectType();
                resolveRelationshipFields(this.objectType);
                this.relationshipFields = relationshipFieldCache.get(this.objectType);
                this.relationshipNames = relationshipNameCache.get(this.objectType);
            }
        }

        void assignParentIds(List<SObject> objects) {
            for (Integer i = 0; i < this.relationshipFields.size(); ++i) {
                Schema.SObjectField parentIdField = this.relationshipFields[i];
                String relationshipName = this.relationshipNames[i];

                for (SObject obj : objects) {
                    if (obj.getSObject(relationshipName) != null &&
                        (obj.get(parentIdField) == null || obj.get(parentIdField) != obj.getSObject(relationshipName).Id)
                    ) {
                        obj.put(parentIdField, obj.getSObject(relationshipName).Id);
                    }
                }
            }
        }
    }

    public class CommitResult implements IDatabaseCommitResult {
        Map<Schema.SObjectType, List<Database.SaveResult>> insertResults { get; set; }
        Map<Schema.SObjectType, List<Database.SaveResult>> updateResults { get; set; }
        Map<Schema.SObjectType, List<Database.UpsertResult>> upsertResults { get; set; }
        Map<Schema.SObjectType, List<Database.DeleteResult>> deleteResults { get; set; }
        Map<Schema.SObjectType, List<Database.UndeleteResult>> undeleteResults { get; set; }
        Map<Schema.SObjectType, List<Database.EmptyRecycleBinResult>> emptyRecycleBinResults { get; set; }

        {
            insertResults = new Map<Schema.SObjectType, List<Database.SaveResult>>();
            updateResults = new Map<Schema.SObjectType, List<Database.SaveResult>>();
            upsertResults = new Map<Schema.SObjectType, List<Database.UpsertResult>>();
            deleteResults = new Map<Schema.SObjectType, List<Database.DeleteResult>>();
            undeleteResults = new Map<Schema.SObjectType, List<Database.UndeleteResult>>();
            emptyRecycleBinResults = new Map<Schema.SObjectType, List<Database.EmptyRecycleBinResult>>();
        }

        public List<Database.SaveResult> getErrorsForInsert(Schema.SObjectType objectType) {
            List<Database.SaveResult> errorResults = new List<Database.SaveResult>();
            for (Database.SaveResult result : this.getResultsForInsert(objectType)) {
                if(!result.isSuccess()) {
                    errorResults.add(result);
                }
            }
            return errorResults;
        }

        public List<Database.SaveResult> getErrorsForUpdate(Schema.SObjectType objectType) {
            List<Database.SaveResult> errorResults = new List<Database.SaveResult>();
            for (Database.SaveResult result : this.getResultsForUpdate(objectType)) {
                if(!result.isSuccess()) {
                    errorResults.add(result);
                }
            }
            return errorResults;
        }

        public List<Database.UpsertResult> getErrorsForUpsert(Schema.SObjectType objectType) {
            List<Database.UpsertResult> errorResults = new List<Database.UpsertResult>();
            for (Database.UpsertResult result : this.getResultsForUpsert(objectType)) {
                if(!result.isSuccess()) {
                    errorResults.add(result);
                }
            }
            return errorResults;
        }

        public List<Database.DeleteResult> getErrorsForDelete(Schema.SObjectType objectType) {
            List<Database.DeleteResult> errorResults = new List<Database.DeleteResult>();
            for (Database.DeleteResult result : this.getResultsForDelete(objectType)) {
                if(!result.isSuccess()) {
                    errorResults.add(result);
                }
            }
            return errorResults;
        }

        public List<Database.UndeleteResult> getErrorsForUndelete(Schema.SObjectType objectType) {
            List<Database.UndeleteResult> errorResults = new List<Database.UndeleteResult>();
            for (Database.UndeleteResult result : this.getResultsForUndelete(objectType)) {
                if(!result.isSuccess()) {
                    errorResults.add(result);
                }
            }
            return errorResults;
        }

        public List<Database.EmptyRecycleBinResult> getErrorsForEmptyRecycleBin(Schema.SObjectType objectType) {
            List<Database.EmptyRecycleBinResult> errorResults = new List<Database.EmptyRecycleBinResult>();
            for (Database.EmptyRecycleBinResult result : this.getResultsForEmptyRecycleBin(objectType)) {
                if(!result.isSuccess()) {
                    errorResults.add(result);
                }
            }
            return errorResults;
        }

        public List<Database.SaveResult> getResultsForInsert(Schema.SObjectType objectType) {
            if (!this.insertResults.containsKey(objectType)) {
                this.insertResults.put(objectType, new List<Database.SaveResult>());
            }
            return this.insertResults.get(objectType);
        }

        public List<Database.SaveResult> getResultsForUpdate(Schema.SObjectType objectType) {
            if (!this.updateResults.containsKey(objectType)) {
                this.updateResults.put(objectType, new List<Database.SaveResult>());
            }
            return this.updateResults.get(objectType);
        }

        public List<Database.UpsertResult> getResultsForUpsert(Schema.SObjectType objectType) {
            if (!this.upsertResults.containsKey(objectType)) {
                this.upsertResults.put(objectType, new List<Database.UpsertResult>());
            }
            return this.upsertResults.get(objectType);
        }

        public List<Database.DeleteResult> getResultsForDelete(Schema.SObjectType objectType) {
            if (!this.deleteResults.containsKey(objectType)) {
                this.deleteResults.put(objectType, new List<Database.DeleteResult>());
            }
            return this.deleteResults.get(objectType);
        }

        public List<Database.UndeleteResult> getResultsForUndelete(Schema.SObjectType objectType) {
            if (!this.undeleteResults.containsKey(objectType)) {
                this.undeleteResults.put(objectType, new List<Database.UndeleteResult>());
            }
            return this.undeleteResults.get(objectType);
        }

        public List<Database.EmptyRecycleBinResult> getResultsForEmptyRecycleBin(Schema.SObjectType objectType) {
            if (!this.emptyRecycleBinResults.containsKey(objectType)) {
                this.emptyRecycleBinResults.put(objectType, new List<Database.EmptyRecycleBinResult>());
            }
            return this.emptyRecycleBinResults.get(objectType);
        }
    }
}
