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

public virtual class DBRepository implements IDBRepository {
    public Schema.SObjectType objectType { get; set; }
    public IDBContext dbcontext { get; set; }

    protected List<SObject> insertedObjects { get; set; }
    protected Map<Id, SObject> updatedObjects { get; set; }
    protected Set<Id> deletedObjectIds { get; set; }

    {
        this.insertedObjects = new List<SObject>();
        this.updatedObjects = new Map<Id, SObject>();
        this.deletedObjectIds = new Set<Id>();
    }

    public virtual IDBRepository config(Schema.SObjectType objectType) {
        this.objectType = objectType;
        return this;
    }

    public virtual IDBRepository config(IDBContext context) {
        this.dbcontext = context;
        return this;
    }

    public virtual List<SObject> fetch(String query) {
        if (String.isNotBlank(query)) {
            return Database.query(String.escapeSingleQuotes(query));
        }
        return new List<SObject>();
    }

    public void relate(SObject obj, Schema.SObjectField to, SObject parent) {
        obj.put(to, parent.Id);
        obj.putSObject(to, parent);
    }

    public virtual void create(SObject obj) {
        if (obj == null) {
            return;
        }
        this.insertedObjects.add(obj);
    }

    public virtual void modify(SObject obj) {
        if (obj == null || obj.Id == null) {
            return;
        }

        if (!this.updatedObjects.containsKey(obj.Id)) {
            this.updatedObjects.put(obj.Id, obj);
            return;
        }

        SObject cacheObj = this.updatedObjects.get(obj.Id);
        if (cacheObj != obj) {
            for (Schema.SObjectField field : obj.getSObjectType().getDescribe().fields.getMap().values()) {
                if (obj.isSet(field)) {
                    cacheObj.put(field, obj.get(field));
                }
            }
        }
    }

    public virtual void modify(SObject obj, List<Schema.SObjectField> fields) {
        if (obj == null || obj.Id == null) {
            return;
        }

        if (fields == null) {
            modify(obj);
            return;
        }

        if (!this.updatedObjects.containsKey(obj.Id)) {
            this.updatedObjects.put(obj.Id, obj);
            return;
        }

        SObject cachedObj = this.updatedObjects.get(obj.Id);
        if (cachedObj != obj) {
            for (Schema.SObjectField field : fields) {
                if (obj.isSet(field)) {
                    cachedObj.put(field, obj.get(field));
                } else {
                    String relationshipName = field.getDescribe().getRelationshipName();
                    if (relationshipName != null) {
                        cachedObj.putSObject(relationshipName, obj.getSObject(relationshipName));
                    }
                }
            }
        }
    }

    public virtual void remove(SObject obj) {
        if (obj == null) {
            return;
        }
        this.deletedObjectIds.add(obj.Id);
    }

    public virtual void save() {
        this.save(true);
    }

    public virtual void save(Boolean allOrNone) {
        if (!this.insertedObjects.isEmpty()) {
            this.dbcontext.insertObjects(this.insertedObjects, allOrNone);
            this.insertedObjects = new List<SObject>();
        }

        if (!this.updatedObjects.isEmpty()) {
            this.dbcontext.updateObjects(this.updatedObjects.values(), allOrNone);
            this.updatedObjects = new Map<Id, SObject>();
        }

        if (!this.deletedObjectIds.isEmpty()) {
            this.dbcontext.deleteObjects(new List<Id>(this.deletedObjectIds), allOrNone);
            this.deletedObjectIds = new Set<Id>();
        }
    }

    public void save(Database.DMLOptions dmlOptions) {
        if (!this.insertedObjects.isEmpty()) {
            this.dbcontext.insertObjects(this.insertedObjects, dmlOptions);
            this.insertedObjects = new List<SObject>();
        }

        if (!this.updatedObjects.isEmpty()) {
            this.dbcontext.updateObjects(this.updatedObjects.values(), dmlOptions);
            this.updatedObjects = new Map<Id, SObject>();
        }

        if (!this.deletedObjectIds.isEmpty()) {
            this.dbcontext.deleteObjects(new List<Id>(this.deletedObjectIds), dmlOptions.optAllOrNone == true);
            this.deletedObjectIds = new Set<Id>();
        }
    }
}
