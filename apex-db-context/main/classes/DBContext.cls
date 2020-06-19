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

public with sharing class DBContext implements IDBContext {

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

    public IDBResult commitObjects() {
        System.Savepoint sp = Database.setSavePoint();
        DBResult result = new DBResult();
		try {
            for (ObjectDescriptor descriptor : objectDescriptors) {
                if (descriptor.objects != null) {
                    descriptor.assignParentIds(descriptor.objects);
                    switch on descriptor.operationType {
                        when DO_INSERT {
                            if (descriptor.allOrNone) {
                                insert descriptor.objects;
                            } else {
                                if (!result.insertResults.containsKey(descriptor.objectType)) {
                                    result.insertResults.put(descriptor.objectType, new List<Database.SaveResult>());
                                }
                                result.insertResults.get(descriptor.objectType).addAll(
                                    Database.insert(descriptor.objects, descriptor.allOrNone));
                            }
                        }
                        when DO_UPSERT {
                            if (descriptor.allOrNone) {
                                upsert descriptor.objects;
                            } else {
                                if (!result.upsertResults.containsKey(descriptor.objectType)) {
                                    result.upsertResults.put(descriptor.objectType, new List<Database.UpsertResult>());
                                }
                                result.upsertResults.get(descriptor.objectType).addAll(
                                    Database.upsert(descriptor.objects, descriptor.allOrNone));
                            }
                        }
                        when DO_UPDATE {
                            if (descriptor.allOrNone) {
                                update descriptor.objects;
                            } else {
                                if (!result.updateResults.containsKey(descriptor.objectType)) {
                                    result.updateResults.put(descriptor.objectType, new List<Database.SaveResult>());
                                }
                                result.updateResults.get(descriptor.objectType).addAll(
                                    Database.update(descriptor.objects, descriptor.allOrNone));
                            }
                        }
                        when DO_DELETE {
                            if (descriptor.allOrNone) {
                                delete descriptor.objects;
                            } else {
                                if (!result.deleteResults.containsKey(descriptor.objectType)) {
                                    result.deleteResults.put(descriptor.objectType, new List<Database.DeleteResult>());
                                }
                                result.deleteResults.get(descriptor.objectType).addAll(
                                    Database.delete(descriptor.objects, descriptor.allOrNone));
                            }
                        }
                        when DO_UNDELETE {
                            if (descriptor.allOrNone) {
                                undelete descriptor.objects;
                            } else {
                                if (!result.undeleteResults.containsKey(descriptor.objectType)) {
                                    result.undeleteResults.put(descriptor.objectType, new List<Database.UndeleteResult>());
                                }
                                result.undeleteResults.get(descriptor.objectType).addAll(
                                    Database.undelete(descriptor.objects, descriptor.allOrNone));
                            }
                        }
                        when DO_EMPTY_RECYCLE_BIN {
                            if (!descriptor.objects.isEmpty()) {
                                if (!result.emptyRecycleBinResults.containsKey(descriptor.objectType)) {
                                    result.emptyRecycleBinResults.put(descriptor.objectType, new List<Database.EmptyRecycleBinResult>());
                                }
                                result.emptyRecycleBinResults.get(descriptor.objectType).addAll(
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
}
