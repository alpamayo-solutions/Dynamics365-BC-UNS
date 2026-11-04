/// <summary>
/// Records person time slices from the Execution app.
/// A session is revised by sending its slices again under a new Session Key: the rows of every other key of the
/// same Session Id become Superseded. A row with Cancelled = true cancels every row of the session.
/// Nothing is posted: person time is kept for reporting and costing outside the posting flow.
/// </summary>
codeunit 50102 "ALP Person Time Svc"
{
    var
        StepResolver: Codeunit "ALP Step Resolver";
        SessionIdRequiredErr: Label 'Session Id and Session Key are required.';
        EmployeeRequiredErr: Label 'Employee No. is required.';
        TimesRequiredErr: Label 'Started At and Ended At are required, and Ended At must not be before Started At.';

    procedure Process(var PersonTime: Record "ALP Person Time Entry")
    var
        Existing: Record "ALP Person Time Entry";
        RoutingLine: Record "Prod. Order Routing Line";
        Employee: Record Employee;
    begin
        PersonTime."Received At" := CurrentDateTime();
        if (PersonTime."Session Id" = '') or ((PersonTime."Session Key" = '') and not PersonTime.Cancelled) then
            Error(SessionIdRequiredErr);

        Existing.SetRange("Event Id", PersonTime."Event Id");
        Existing.SetFilter(Result, '<>%1', Existing.Result::Duplicate);
        if not Existing.IsEmpty() then begin
            PersonTime.Result := PersonTime.Result::Duplicate;
            PersonTime.Status := PersonTime.Status::Superseded;
            exit;
        end;

        if PersonTime.Cancelled then begin
            SetSessionStatus(PersonTime."Session Id", '', "ALP Person Time Status"::Cancelled);
            PersonTime.Status := PersonTime.Status::Cancelled;
            PersonTime.Result := PersonTime.Result::Recorded;
            exit;
        end;

        if PersonTime."Employee No." = '' then
            Error(EmployeeRequiredErr);
        Employee.Get(PersonTime."Employee No.");
        if (PersonTime."Started At" = 0DT) or (PersonTime."Ended At" = 0DT) or (PersonTime."Ended At" < PersonTime."Started At") then
            Error(TimesRequiredErr);

        if PersonTime."Step Id" <> '' then begin
            StepResolver.GetReleasedRoutingLine(PersonTime."Step Id", RoutingLine);
            PersonTime."Prod. Order No." := RoutingLine."Prod. Order No.";
            PersonTime."Routing Reference No." := RoutingLine."Routing Reference No.";
            PersonTime."Operation No." := RoutingLine."Operation No.";
        end;
        if PersonTime."Work Place Type" <> '' then
            PersonTime."Work Place Type" := CopyStr(Format(StepResolver.ParseWorkPlaceType(PersonTime."Work Place Type")), 1, MaxStrLen(PersonTime."Work Place Type"));

        PersonTime.Minutes := Round((PersonTime."Ended At" - PersonTime."Started At") / 60000, 0.01);
        SetSessionStatus(PersonTime."Session Id", PersonTime."Session Key", "ALP Person Time Status"::Superseded);
        PersonTime.Status := PersonTime.Status::Active;
        PersonTime.Result := PersonTime.Result::Recorded;
    end;

    /// <summary>Sets every active row of the session whose key differs from KeepKey to NewStatus.</summary>
    local procedure SetSessionStatus(SessionId: Text[50]; KeepKey: Text[100]; NewStatus: Enum "ALP Person Time Status")
    var
        Entry: Record "ALP Person Time Entry";
    begin
        Entry.SetCurrentKey("Session Id", Status);
        Entry.SetRange("Session Id", SessionId);
        Entry.SetRange(Status, Entry.Status::Active);
        if KeepKey <> '' then
            Entry.SetFilter("Session Key", '<>%1', KeepKey);
        Entry.ModifyAll(Status, NewStatus);
    end;
}
