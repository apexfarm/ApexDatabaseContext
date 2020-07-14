public with sharing class DBException extends Exception {
    public DBContext.SavePoints savePoints { get; set; }
    Exception ex { get; set; }

    public DBException(DBContext.SavePoints savePoints, Exception ex) {
        this(ex);
        this.savePoints = savePoints;
        this.ex = ex;
    }

    public override List<String> getDmlFieldNames(Integer arg0) {
        return ex.getDmlFieldNames(arg0);
    }

    public override List<Schema.SObjectField> getDmlFields(Integer arg0) {
        return ex.getDmlFields(arg0);
    }

    public override String getDmlId(Integer arg0) {
        return ex.getDmlId(arg0);
    }

    public override Integer getDmlIndex(Integer arg0) {
        return ex.getDmlIndex(arg0);
    }

    public override String getDmlMessage(Integer arg0) {
        return ex.getDmlMessage(arg0);
    }

    public override String getDmlStatusCode(Integer arg0) {
        return ex.getDmlStatusCode(arg0);
    }

    public override System.StatusCode getDmlType(Integer arg0) {
        return ex.getDmlType(arg0);
    }

    public override Integer getNumDml() {
        return ex.getNumDml();
    }

    public override String getMessage() {
        return ex.getMessage();
    }

    public override String getStackTraceString() {
        return ex.getStackTraceString();
    }

    public override Integer getLineNumber() {
        return ex.getLineNumber();
    }

    public void rollback() {
        savePoints.rollback();
    }
}
