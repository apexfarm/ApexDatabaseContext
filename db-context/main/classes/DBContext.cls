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

public virtual class DBContext implements IDBContext {

    static Map<Schema.SObjectType, List<Schema.SObjectField>> relationshipFieldCache { get; set; }
    static Map<Schema.SObjectType, List<String>> relationshipNameCache { get; set; }

    protected List<DMLDescriptor> dmlDescriptors { get; set; }
    protected Map<Schema.SObjectType, DMLData> dmlData { get; set; } // Single Source of Truth

    static {
        relationshipFieldCache = new Map<Schema.SObjectType, List<Schema.SObjectField>>();
        relationshipNameCache = new Map<Schema.SObjectType, List<String>>();
    }

    {
        this.dmlDescriptors = new List<DMLDescriptor>();
        this.dmlData = new Map<Schema.SObjectType, DMLData>();
    }

    DMLData getDmlData(Schema.SObjectType objectType) {
        if (!this.dmlData.containsKey(objectType)) {
            this.dmlData.put(objectType, new DMLData(objectType));
        }
        return this.dmlData.get(objectType);
    }

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
        register(DMLOperation.DO_INSERT, objects, true);
    }

    public void insertObjects(List<SObject> objects, Boolean allOrNone) {
        register(DMLOperation.DO_INSERT, objects, allOrNone);
    }

    public void upsertObjects(List<SObject> objects) {
        register(DMLOperation.DO_UPSERT, objects, true);
    }

    public void upsertObjects(List<SObject> objects, Boolean allOrNone) {
        register(DMLOperation.DO_UPSERT, objects, allOrNone);
    }

    public void updateObjects(List<SObject> objects) {
        register(DMLOperation.DO_UPDATE, objects, true);
    }

    public void updateObjects(List<SObject> objects, Boolean allOrNone) {
        register(DMLOperation.DO_UPDATE, objects, allOrNone);
    }

    public List<SObject> updateObjects(List<SObject> objects, List<Schema.SObjectField> fields) {
        if (objects != null) {
            Schema.SObjectType objectType = objects.getSObjectType();
            return this.getDmlData(objectType).refresh(objects, fields);
        }
        return objects;
    }

    public void deleteObjects(List<SObject> objects) {
        register(DMLOperation.DO_DELETE, objects, true);
    }

    public void deleteObjects(List<SObject> objects, Boolean allOrNone) {
        register(DMLOperation.DO_DELETE, objects, allOrNone);
    }

    public void undeleteObjects(List<SObject> objects) {
        register(DMLOperation.DO_UNDELETE, objects, true);
    }

    public void undeleteObjects(List<SObject> objects, Boolean allOrNone) {
        register(DMLOperation.DO_UNDELETE, objects, allOrNone);
    }

    public void emptyRecycleBin(List<SObject> objects) {
        register(DMLOperation.DO_EMPTY_RECYCLE_BIN, objects, true);
    }

    public void emptyRecycleBin(List<SObject> objects, Boolean allOrNone) {
        register(DMLOperation.DO_EMPTY_RECYCLE_BIN, objects, allOrNone);
    }

    public virtual IDBResult commitObjects() {
        System.Savepoint sp = Database.setSavePoint();
        DBResult result = new DBResult();
		try {
            for (DMLDescriptor dmlDescriptor : this.dmlDescriptors) {
                switch on dmlDescriptor.dmlOperation {
                    when DO_INSERT {
                        if (dmlDescriptor.objects != null) {
                            dmlDescriptor.assignParentIds();
                            List<Database.SaveResult> results = Database.update(dmlDescriptor.objects, dmlDescriptor.allOrNone);

                            if (!dmlDescriptor.allOrNone) {
                                if (!result.insertResults.containsKey(dmlDescriptor.objectType)) {
                                    result.insertResults.put(dmlDescriptor.objectType, new List<Database.SaveResult>());
                                }
                                result.insertResults.get(dmlDescriptor.objectType).addAll(results);
                            }
                        }
                    }
                    when DO_UPSERT {
                        if (dmlDescriptor.objects != null) {
                            dmlDescriptor.assignParentIds();
                            List<Database.UpsertResult> results = Database.upsert(dmlDescriptor.objects, dmlDescriptor.allOrNone);

                            if (!dmlDescriptor.allOrNone) {
                                if (!result.upsertResults.containsKey(dmlDescriptor.objectType)) {
                                    result.upsertResults.put(dmlDescriptor.objectType, new List<Database.UpsertResult>());
                                }
                                result.upsertResults.get(dmlDescriptor.objectType).addAll(results);
                            }
                        }
                    }
                    when DO_UPDATE {
                        if (dmlDescriptor.objects != null) {
                            dmlDescriptor.assignParentIds();
                            List<Database.SaveResult> results = Database.update(dmlDescriptor.objects, dmlDescriptor.allOrNone);

                            if (!dmlDescriptor.allOrNone) {
                                if (!result.updateResults.containsKey(dmlDescriptor.objectType)) {
                                    result.updateResults.put(dmlDescriptor.objectType, new List<Database.SaveResult>());
                                }
                                result.updateResults.get(dmlDescriptor.objectType).addAll(results);
                            }
                        }
                    }
                    when DO_DELETE {
                        if (dmlDescriptor.objectIds != null) {
                            List<Database.DeleteResult> results = Database.delete(new List<Id>(dmlDescriptor.objectIds), dmlDescriptor.allOrNone);
                            System.debug(results);

                            if (!dmlDescriptor.allOrNone) {
                                if (!result.deleteResults.containsKey(dmlDescriptor.objectType)) {
                                    result.deleteResults.put(dmlDescriptor.objectType, new List<Database.DeleteResult>());
                                }
                                result.deleteResults.get(dmlDescriptor.objectType).addAll(results);
                            }
                        }
                    }
                    when DO_UNDELETE {
                        if (dmlDescriptor.objectIds != null) {
                            List<Database.UndeleteResult> results = Database.undelete(new List<Id>(dmlDescriptor.objectIds), dmlDescriptor.allOrNone);

                            if (!dmlDescriptor.allOrNone) {
                                if (!result.undeleteResults.containsKey(dmlDescriptor.objectType)) {
                                    result.undeleteResults.put(dmlDescriptor.objectType, new List<Database.UndeleteResult>());
                                }
                                result.undeleteResults.get(dmlDescriptor.objectType).addAll(results);
                            }
                        }
                    }
                    when DO_EMPTY_RECYCLE_BIN {
                        if (dmlDescriptor.objectIds != null && !dmlDescriptor.objectIds.isEmpty()) {
                            List<Database.EmptyRecycleBinResult> results = Database.emptyRecycleBin(new List<Id>(dmlDescriptor.objectIds));

                            if (!dmlDescriptor.allOrNone) {
                                if (!result.emptyRecycleBinResults.containsKey(dmlDescriptor.objectType)) {
                                    result.emptyRecycleBinResults.put(dmlDescriptor.objectType, new List<Database.EmptyRecycleBinResult>());
                                }
                                result.emptyRecycleBinResults.get(dmlDescriptor.objectType).addAll(results);
                            }
                        }
                    }
                }
            }
            this.dmlDescriptors.clear();
		} catch (Exception ex) {
			Database.rollback(sp);
			throw ex;
		}
        return result;
    }

    private void register(DMLOperation dmlOperation, List<SObject> objects, Boolean allOrNone) {
        if (objects != null) {
            Schema.SObjectType objectType = objects.getSObjectType();
            this.getDmlData(objectType).register(dmlOperation, objects);
            this.dmlDescriptors.add(new DMLDescriptor(dmlOperation, objectType, objects, allOrNone));
        }
    }

    public enum DMLOperation {
        DO_INSERT,
        DO_UPSERT,
        DO_UPDATE,
        DO_DELETE,
        DO_UNDELETE,
        DO_EMPTY_RECYCLE_BIN
    }

    public virtual class DMLDescriptor {
        public DMLOperation dmlOperation { get; set; }
        public Boolean allOrNone { get; set; }
        public Schema.SObjectType objectType { get; set; }
        public List<SObject> objects { get; set; }
        public Set<Id> objectIds { get; set; }
        List<Schema.SObjectField> relationshipFields { get; set; }
        List<String> relationshipNames { get; set; }

        DMLDescriptor(DMLOperation dmlOperation, SObjectType objectType, List<SObject> objects, Boolean allOrNone) {
            this.dmlOperation = dmlOperation;
            this.objectType = objectType;
            switch on dmlOperation {
                when DO_INSERT, DO_UPDATE, DO_UPSERT {
                    this.objects = objects;
                }
                when DO_DELETE, DO_UNDELETE, DO_EMPTY_RECYCLE_BIN {
                    this.objectIds = new Map<Id, SObject>(objects).keySet();
                }
            }
            this.allOrNone = allOrNone;

            resolveRelationshipFields(this.objectType);
            this.relationshipFields = relationshipFieldCache.get(this.objectType);
            this.relationshipNames = relationshipNameCache.get(this.objectType);
        }

        public virtual void assignParentIds() {
            for (Integer i = 0; i < this.relationshipFields.size(); ++i) {
                Schema.SObjectField parentIdField = this.relationshipFields[i];
                String relationshipName = this.relationshipNames[i];

                for (SObject obj : this.objects) {
                    if (obj.getSObject(relationshipName) != null &&
                        (obj.get(parentIdField) == null || obj.get(parentIdField) != obj.getSObject(relationshipName).Id)
                    ) {
                        obj.put(parentIdField, obj.getSObject(relationshipName).Id);
                    }
                }
            }
        }
    }

    class DMLData {
        Schema.SObjectType objectType { get; set; }

        List<SObject> insertedObjects { get; set; } // can be consolidated
        Map<Id, SObject> updatedObjects { get; set; } // can be consolidated
        Set<Id> deletedObjects { get; set; } // can be consolidated
        Set<Id> emptiedObjects { get; set; } // can be consolidated
        Set<Id> undeletedObjects { get; set; } // can be consolidated

        DMLData(Schema.SObjectType objectType) {
            this.objectType = objectType;
            insertedObjects = new List<SObject>();
            updatedObjects = new Map<Id, SObject>();
            deletedObjects = new Set<Id>();
            emptiedObjects = new Set<Id>();
            undeletedObjects = new Set<Id>();
        }

        List<SObject> refresh(List<SObject> objects, List<Schema.SObjectField> fields) {
            if (this.updatedObjects.isEmpty()) {
                return objects;
            }

            List<SObject> replacedObjects = new List<SObject>();
            for (SObject obj : objects) {
                SObject existingObj = this.updatedObjects.get(obj.Id);
                if (existingObj != null) {
                    for (Schema.SObjectField field : fields) {
                        existingObj.put(field, obj.get(field));
                    }
                    replacedObjects.add(existingObj);
                } else {
                    this.updatedObjects.put(obj.Id, obj);
                    replacedObjects.add(obj);
                }
            }
            return replacedObjects;
        }

        void register(DMLOperation dmlOperation, List<SObject> objects) {
            switch on dmlOperation {
                when DO_INSERT {
                    this.insertedObjects.addAll(objects);
                }
                when DO_UPSERT {
                    for (SObject obj : objects) {
                        if (obj.Id == null) {
                            this.insertedObjects.add(obj);
                        } else {
                            this.updatedObjects.put(obj.Id, obj);
                        }
                    }
                }
                when DO_UPDATE {
                    this.updatedObjects.putAll(new Map<Id, SObject>(objects));
                }
                when DO_DELETE {
                    this.deletedObjects.addAll(new Map<Id, SObject>(objects).keySet());
                }
                when DO_UNDELETE {
                    this.undeletedObjects.addAll(new Map<Id, SObject>(objects).keySet());
                }
                when DO_EMPTY_RECYCLE_BIN {
                    this.emptiedObjects.addAll(new Map<Id, SObject>(objects).keySet());
                }
            }
        }
    }

    public class DBResult implements IDBResult {
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
}
