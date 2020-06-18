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
 */

public interface IDatabaseCommitResult {
    List<Database.SaveResult> getErrorsForInsert(Schema.SObjectType objectType);
    List<Database.SaveResult> getErrorsForUpdate(Schema.SObjectType objectType);
    List<Database.UpsertResult> getErrorsForUpsert(Schema.SObjectType objectType);
    List<Database.DeleteResult> getErrorsForDelete(Schema.SObjectType objectType);
    List<Database.UndeleteResult> getErrorsForUndelete(Schema.SObjectType objectType);
    List<Database.EmptyRecycleBinResult> getErrorsForEmptyRecycleBin(Schema.SObjectType objectType);

    List<Database.SaveResult> getResultsForInsert(Schema.SObjectType objectType);
    List<Database.SaveResult> getResultsForUpdate(Schema.SObjectType objectType);
    List<Database.UpsertResult> getResultsForUpsert(Schema.SObjectType objectType);
    List<Database.DeleteResult> getResultsForDelete(Schema.SObjectType objectType);
    List<Database.UndeleteResult> getResultsForUndelete(Schema.SObjectType objectType);
    List<Database.EmptyRecycleBinResult> getResultsForEmptyRecycleBin(Schema.SObjectType objectType);
}