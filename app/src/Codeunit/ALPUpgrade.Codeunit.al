/// <summary>
/// Upgrade from 1.x to 2.0. The 1.x execution tables (inbox, operation execution, work log, corrections,
/// time attribution, topic mapping) are obsolete and their data is not carried over: the 1.x surface was never
/// used in production and 2.0 records execution facts in new tables. The rows are deleted once, guarded by an
/// upgrade tag, so a repeated upgrade does nothing.
/// </summary>
codeunit 50105 "ALP Upgrade"
{
    Subtype = Upgrade;

    var
        DropV1DataTagLbl: Label 'ALP-UNS-2.0-DROP-V1-EXECUTION-DATA', Locked = true;

    trigger OnUpgradePerCompany()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(DropV1DataTagLbl) then
            exit;
        DropV1ExecutionData();
        UpgradeTag.SetUpgradeTag(DropV1DataTagLbl);
    end;

#pragma warning disable AL0432
    local procedure DropV1ExecutionData()
    var
        IntegrationInbox: Record "ALP Integration Inbox";
        OperationExecution: Record "ALP Operation Execution";
        TopicMapping: Record "ALP UNS Topic Mapping";
        WorkLogEntry: Record "ALP Work Log Entry";
        ExecutionCorrection: Record "ALP Execution Correction";
        TimeAttribution: Record "ALP Execution Time Attribution";
    begin
        IntegrationInbox.DeleteAll();
        OperationExecution.DeleteAll();
        TopicMapping.DeleteAll();
        WorkLogEntry.DeleteAll();
        ExecutionCorrection.DeleteAll();
        TimeAttribution.DeleteAll();
    end;
#pragma warning restore AL0432

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(DropV1DataTagLbl);
    end;
}
