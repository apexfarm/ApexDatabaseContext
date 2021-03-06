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
    static SavePoints savePoints { get; set; }

    static {
        relationshipFieldCache = new Map<Schema.SObjectType, List<Schema.SObjectField>>();
        savePoints = new SavePoints();
    }

    static void setRelationshipFields(Schema.SObjectType objectType) {
        if (!relationshipFieldCache.containsKey(objectType)) {
            List<Schema.SObjectField> relationshipFields = new List<Schema.SObjectField>();

            for (Schema.SObjectField field : objectType.getDescribe().fields.getMap().values()) {
                Schema.DescribeFieldResult dfr = field.getDescribe();
                String relationshipName = field.getDescribe().getRelationshipName();
                if (relationshipName != null && (dfr.isCreateable() || dfr.isUpdateable())) {
                    relationshipFields.add(field);
                }
            }
            relationshipFieldCache.put(objectType, relationshipFields);
        }
    }

    protected List<IDBContext> childContexts { get; set; }
    protected List<DMLDescriptor> dmlDescriptors { get; set; }

    {
        this.childContexts = new List<IDBContext>();
        this.dmlDescriptors = new List<DMLDescriptor>();
    }

    protected List<IDBContext> childContexts() {
        return this.childContexts;
    }

    protected List<DMLDescriptor> dmlDescriptors() {
        return this.dmlDescriptors;
    }

    public virtual IDBContext create() {
        IDBContext context = new DBContext();
        this.childContexts.add(context);
        return context;
    }

    public void insertObjects(List<SObject> objects) {
        register(DMLOperation.DO_INSERT, objects, true);
    }

    public void insertObjects(List<SObject> objects, Boolean allOrNone) {
        register(DMLOperation.DO_INSERT, objects, allOrNone);
    }

    public void insertObjects(List<SObject> objects, Database.DMLOptions dmlOptions) {
        register(DMLOperation.DO_INSERT, objects, dmlOptions);
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

    public void updateObjects(List<SObject> objects, Database.DMLOptions dmlOptions) {
        register(DMLOperation.DO_UPDATE, objects, dmlOptions);
    }

    public void deleteObjects(List<SObject> objects) {
        register(DMLOperation.DO_DELETE, objects, true);
    }

    public void deleteObjects(List<SObject> objects, Boolean allOrNone) {
        register(DMLOperation.DO_DELETE, objects, allOrNone);
    }

    public void deleteObjects(List<Id> objectIds) {
        register(DMLOperation.DO_DELETE, objectIds, true);
    }

    public void deleteObjects(List<Id> objectIds, Boolean allOrNone) {
        register(DMLOperation.DO_DELETE, objectIds, allOrNone);
    }

    public void undeleteObjects(List<SObject> objects) {
        register(DMLOperation.DO_UNDELETE, objects, true);
    }

    public void undeleteObjects(List<SObject> objects, Boolean allOrNone) {
        register(DMLOperation.DO_UNDELETE, objects, allOrNone);
    }

    public void undeleteObjects(List<Id> objectIds) {
        register(DMLOperation.DO_UNDELETE, objectIds, true);
    }

    public void undeleteObjects(List<Id> objectIds, Boolean allOrNone) {
        register(DMLOperation.DO_UNDELETE, objectIds, allOrNone);
    }

    public void emptyRecycleBin(List<SObject> objects) {
        register(DMLOperation.DO_EMPTY_RECYCLE_BIN, objects, true);
    }

    public void emptyRecycleBin(List<SObject> objects, Boolean allOrNone) {
        register(DMLOperation.DO_EMPTY_RECYCLE_BIN, objects, allOrNone);
    }

    public void emptyRecycleBin(List<Id> objectIds) {
        register(DMLOperation.DO_EMPTY_RECYCLE_BIN, objectIds, true);
    }

    public void emptyRecycleBin(List<Id> objectIds, Boolean allOrNone) {
        register(DMLOperation.DO_EMPTY_RECYCLE_BIN, objectIds, allOrNone);
    }

    public virtual IDBResult commitObjects() {
        Savepoint sp = savePoints.addSavePoint();
        DBResult result = new DBResult(savePoints, sp);
		try {
            commitContext(this, result);
		} catch (Exception ex) {
			savePoints.rollback(sp);
			throw new DBException(savePoints, ex);
		}
        return result;
    }

    protected virtual void commitContext(IDBContext context, IDBResult result) {
        for (IDBContext childContext : ((DBContext)context).childContexts()) {
            commitContext(childContext, result);
        }

        for (DMLDescriptor dmlDescriptor : ((DBContext)context).dmlDescriptors()) {
            commitObjects(dmlDescriptor, result);
        }
        ((DBContext)context).dmlDescriptors().clear();
    }

    protected virtual void commitObjects(DMLDescriptor dmlDescriptor, IDBResult result) {
        DBResult dbResult = (DBResult)result;
        switch on dmlDescriptor.dmlOperation {
            when DO_INSERT {
                if (dmlDescriptor.objects != null) {
                    dmlDescriptor.assignParentIds();

                    List<Database.SaveResult> results;
                    if (dmlDescriptor.dmlOptions != null) {
                        results = Database.insert(dmlDescriptor.objects, dmlDescriptor.dmlOptions);
                    } else {
                        results = Database.insert(dmlDescriptor.objects, dmlDescriptor.allOrNone);
                    }

                    if (dmlDescriptor.allOrNone == false || (dmlDescriptor.dmlOptions != null
                        && dmlDescriptor.dmlOptions.optAllOrNone != true)) {

                        if (!dbResult.insertResults.containsKey(dmlDescriptor.objectType)) {
                            dbResult.insertResults.put(dmlDescriptor.objectType, new List<Database.SaveResult>());
                        }
                        dbResult.insertResults.get(dmlDescriptor.objectType).addAll(results);
                    }
                }
            }
            when DO_UPSERT {
                if (dmlDescriptor.objects != null) {
                    dmlDescriptor.assignParentIds();
                    List<Database.UpsertResult> results = Database.upsert(dmlDescriptor.objects, dmlDescriptor.allOrNone);

                    if (!dmlDescriptor.allOrNone) {
                        if (!dbResult.upsertResults.containsKey(dmlDescriptor.objectType)) {
                            dbResult.upsertResults.put(dmlDescriptor.objectType, new List<Database.UpsertResult>());
                        }
                        dbResult.upsertResults.get(dmlDescriptor.objectType).addAll(results);
                    }
                }
            }
            when DO_UPDATE {
                if (dmlDescriptor.objects != null) {
                    dmlDescriptor.assignParentIds();

                    List<Database.SaveResult> results;
                    if (dmlDescriptor.dmlOptions != null) {
                        results = Database.update(dmlDescriptor.objects, dmlDescriptor.dmlOptions);
                    } else {
                        results = Database.update(dmlDescriptor.objects, dmlDescriptor.allOrNone);
                    }

                    if (dmlDescriptor.allOrNone == false || (dmlDescriptor.dmlOptions != null
                        && dmlDescriptor.dmlOptions.optAllOrNone != true)) {

                        if (!dbResult.updateResults.containsKey(dmlDescriptor.objectType)) {
                            dbResult.updateResults.put(dmlDescriptor.objectType, new List<Database.SaveResult>());
                        }
                        dbResult.updateResults.get(dmlDescriptor.objectType).addAll(results);
                    }
                }
            }
            when DO_DELETE {
                if (dmlDescriptor.objectIds != null) {
                    List<Database.DeleteResult> results = Database.delete(dmlDescriptor.objectIds, dmlDescriptor.allOrNone);

                    if (!dmlDescriptor.allOrNone) {
                        if (!dbResult.deleteResults.containsKey(dmlDescriptor.objectType)) {
                            dbResult.deleteResults.put(dmlDescriptor.objectType, new List<Database.DeleteResult>());
                        }
                        dbResult.deleteResults.get(dmlDescriptor.objectType).addAll(results);
                    }
                }
            }
            when DO_UNDELETE {
                if (dmlDescriptor.objectIds != null) {
                    List<Database.UndeleteResult> results = Database.undelete(dmlDescriptor.objectIds, dmlDescriptor.allOrNone);

                    if (!dmlDescriptor.allOrNone) {
                        if (!dbResult.undeleteResults.containsKey(dmlDescriptor.objectType)) {
                            dbResult.undeleteResults.put(dmlDescriptor.objectType, new List<Database.UndeleteResult>());
                        }
                        dbResult.undeleteResults.get(dmlDescriptor.objectType).addAll(results);
                    }
                }
            }
            when DO_EMPTY_RECYCLE_BIN {
                if (dmlDescriptor.objectIds != null && !dmlDescriptor.objectIds.isEmpty()) {
                    List<Database.EmptyRecycleBinResult> results = Database.emptyRecycleBin(dmlDescriptor.objectIds);

                    if (!dmlDescriptor.allOrNone) {
                        if (!dbResult.emptyRecycleBinResults.containsKey(dmlDescriptor.objectType)) {
                            dbResult.emptyRecycleBinResults.put(dmlDescriptor.objectType, new List<Database.EmptyRecycleBinResult>());
                        }
                        dbResult.emptyRecycleBinResults.get(dmlDescriptor.objectType).addAll(results);
                    }
                }
            }
        }
    }

    private void register(DMLOperation dmlOperation, List<SObject> objects, Database.DMLOptions dmlOptions) {
        if (objects != null && !objects.isEmpty()) {
            Schema.SObjectType objectType = objects[0].getSObjectType();
            this.dmlDescriptors.add(new DMLDescriptor(dmlOperation, objectType, objects, dmlOptions));
        }
    }

    private void register(DMLOperation dmlOperation, List<SObject> objects, Boolean allOrNone) {
        if (objects != null && !objects.isEmpty()) {
            Schema.SObjectType objectType = objects[0].getSObjectType();
            this.dmlDescriptors.add(new DMLDescriptor(dmlOperation, objectType, objects, allOrNone));
        }
    }

    private void register(DMLOperation dmlOperation, List<Id> objectIds, Boolean allOrNone) {
        if (objectIds != null && !objectIds.isEmpty()) {
            Schema.SObjectType objectType = objectIds[0].getSobjectType();
            this.dmlDescriptors.add(new DMLDescriptor(dmlOperation, objectType, objectIds, allOrNone));
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
        public Database.DMLOptions dmlOptions { get; set; }
        public Schema.SObjectType objectType { get; set; }

        public List<SObject> objects { get; set; }
        public List<Id> objectIds { get; set; }

        List<Schema.SObjectField> relationshipFields { get; set; }

        DMLDescriptor(DMLOperation dmlOperation, SObjectType objectType) {
            this.dmlOperation = dmlOperation;
            this.objectType = objectType;
            setRelationshipFields(this.objectType);
            this.relationshipFields = relationshipFieldCache.get(this.objectType);
        }

        DMLDescriptor(DMLOperation dmlOperation, SObjectType objectType, List<SObject> objects, Boolean allOrNone) {
            this(dmlOperation, objectType);
            switch on dmlOperation {
                when DO_INSERT, DO_UPDATE, DO_UPSERT {
                    this.objects = objects;
                }
                when DO_DELETE, DO_UNDELETE, DO_EMPTY_RECYCLE_BIN {
                    this.objectIds = new List<Id>((new Map<Id, SObject>(objects)).keySet());
                }
            }
            this.allOrNone = allOrNone;
        }

        DMLDescriptor(DMLOperation dmlOperation, SObjectType objectType, List<SObject> objects, Database.DMLOptions dmlOptions) {
            this(dmlOperation, objectType);
            switch on dmlOperation {
                when DO_INSERT, DO_UPDATE, DO_UPSERT {
                    this.objects = objects;
                }
            }
            this.dmlOptions = dmlOptions;
        }


        DMLDescriptor(DMLOperation dmlOperation, SObjectType objectType, List<Id> objectIds, Boolean allOrNone) {
            this(dmlOperation, objectType);
            switch on dmlOperation {
                when DO_DELETE, DO_UNDELETE, DO_EMPTY_RECYCLE_BIN {
                    this.objectIds = objectIds;
                }
            }
            this.allOrNone = allOrNone;
        }

        public virtual void assignParentIds() {
            for (Schema.SObjectField parentIdField : this.relationshipFields) {
                for (SObject obj : this.objects) {
                    try {
                        SObject parentObj = obj.getSObject(parentIdField);
                        if (parentObj != null) {
                            if (obj.get(parentIdField) == null) {
                                obj.put(parentIdField, parentObj.Id);
                            }
                        }
                    } catch (SObjectException ex) {

                    }
                }
            }
        }
    }

    public class SavePoints {
        List<SavePoint> sps { get; set; }

        SavePoints() {
            this.sps = new List<SavePoint>();
        }

        SavePoint addSavePoint() {
            SavePoint sp = Database.setSavePoint();
            this.sps.add(sp);
            return sp;
        }

        public void rollback() {
            if (!this.sps.isEmpty()) {
                Database.rollback(this.sps[0]);
                this.sps.clear();
            }
        }

        public void rollback(SavePoint sp) {
            Integer index = this.sps.indexOf(sp);
            if (index != -1) {
                Database.rollback(sp);
                for (Integer len = this.sps.size(); len > index; --len) {
                    this.sps.remove(len -1);
                }
            }
        }
    }

    public class DBResult implements IDBResult {
        Savepoints savePoints { get; set; }
        Savepoint sp { get; set; }
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

        DBResult(SavePoints savePoints, SavePoint sp) {
            this.savePoints = savePoints;
            this.sp = sp;
        }

        public void rollback() {
            this.savePoints.rollback(this.sp);
        }

        public List<DMLResult> getInsertErrors(Schema.SObjectType objectType) {
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

        public List<DMLResult> getUpdateErrors(Schema.SObjectType objectType) {
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

        public List<DMLResult> getUpsertErrors(Schema.SObjectType objectType) {
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

        public List<DMLResult> getDeleteErrors(Schema.SObjectType objectType) {
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

        public List<DMLResult> getUndeleteErrors(Schema.SObjectType objectType) {
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

        public List<DMLResult> getEmptyRecycleBinErrors(Schema.SObjectType objectType) {
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

        public List<DMLResult> getInsertResults(Schema.SObjectType objectType) {
            List<DMLResult> dmlResults = new List<DMLResult>();

            if (this.insertResults.containsKey(objectType)) {
                for (Database.SaveResult result : this.insertResults.get(objectType)) {
                    dmlResults.add(new DMLResult(result, true));
                }
            }
            return dmlResults;
        }

        public List<DMLResult> getUpdateResults(Schema.SObjectType objectType) {
            List<DMLResult> dmlResults = new List<DMLResult>();

            if (this.updateResults.containsKey(objectType)) {
                for (Database.SaveResult result : this.updateResults.get(objectType)) {
                    dmlResults.add(new DMLResult(result, false));
                }
            }
            return dmlResults;
        }

        public List<DMLResult> getUpsertResults(Schema.SObjectType objectType) {
            List<DMLResult> dmlResults = new List<DMLResult>();

            if (this.upsertResults.containsKey(objectType)) {
                for (Database.UpsertResult result : this.upsertResults.get(objectType)) {
                    dmlResults.add(new DMLResult(result));
                }
            }
            return dmlResults;
        }

        public List<DMLResult> getDeleteResults(Schema.SObjectType objectType) {
            List<DMLResult> dmlResults = new List<DMLResult>();

            if (this.deleteResults.containsKey(objectType)) {
                for (Database.DeleteResult result : this.deleteResults.get(objectType)) {
                    dmlResults.add(new DMLResult(result));
                }
            }
            return dmlResults;
        }

        public List<DMLResult> getUndeleteResults(Schema.SObjectType objectType) {
            List<DMLResult> dmlResults = new List<DMLResult>();

            if (this.undeleteResults.containsKey(objectType)) {
                for (Database.UndeleteResult result : this.undeleteResults.get(objectType)) {
                    dmlResults.add(new DMLResult(result));
                }
            }
            return dmlResults;
        }

        public List<DMLResult> getEmptyRecycleBinResults(Schema.SObjectType objectType) {
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
