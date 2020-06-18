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

public interface IDatabaseContext {
    void insertObjects(List<SObject> objects);
    void insertObjects(List<SObject> objects, Boolean allOrNone);
    void upsertObjects(List<SObject> objects);
    void upsertObjects(List<SObject> objects, Boolean allOrNone);
    void updateObjects(List<SObject> objects);
    void updateObjects(List<SObject> objects, Boolean allOrNone);
    void deleteObjects(List<SObject> objects);
    void deleteObjects(List<SObject> objects, Boolean allOrNone);
    void undeleteObjects(List<SObject> objects);
    void undeleteObjects(List<SObject> objects, Boolean allOrNone);

    void emptyRecycleBin(List<SObject> objects);

    IDatabaseCommitResult commitObjects();
}