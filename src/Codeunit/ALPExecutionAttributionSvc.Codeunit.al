codeunit 50015 "ALP Execution Attribution Svc"
{
    procedure RefreshAll()
    var
        Attribution: Record "ALP Execution Time Attribution";
    begin
        Attribution.DeleteAll(true);
        BuildMachineAttributions();
        BuildOperatorAttributions();
    end;

    local procedure BuildMachineAttributions()
    var
        WorkLogEntry: Record "ALP Work Log Entry";
        AttributionType: Enum "ALP Time Attribution Type";
        ProcessedTasks: Dictionary of [Text, Boolean];
        TaskKey: Text;
        Seconds: Decimal;
    begin
        WorkLogEntry.SetRange("Event Type", WorkLogEntry."Event Type"::Execution);
        WorkLogEntry.SetRange(Status, WorkLogEntry.Status::Closed);
        if not WorkLogEntry.FindSet() then
            exit;

        repeat
            TaskKey := BuildTaskKey(WorkLogEntry."Order No.", WorkLogEntry."Operation No.", WorkLogEntry."Work Center No.");
            if not ProcessedTasks.ContainsKey(TaskKey) then begin
                Seconds := CalculateMachineSeconds(WorkLogEntry."Order No.", WorkLogEntry."Operation No.", WorkLogEntry."Work Center No.");
                InsertAttribution(AttributionType::Machine, WorkLogEntry."Order No.", WorkLogEntry."Operation No.", WorkLogEntry."Work Center No.", '', Seconds, CountTaskIntervals(WorkLogEntry."Order No.", WorkLogEntry."Operation No.", WorkLogEntry."Work Center No."));
                ProcessedTasks.Add(TaskKey, true);
            end;
        until WorkLogEntry.Next() = 0;
    end;

    local procedure BuildOperatorAttributions()
    var
        WorkLogEntry: Record "ALP Work Log Entry";
        AttributionType: Enum "ALP Time Attribution Type";
        ProcessedOperatorTasks: Dictionary of [Text, Boolean];
        OperatorTaskKey: Text;
        Seconds: Decimal;
    begin
        WorkLogEntry.SetRange("Event Type", WorkLogEntry."Event Type"::Execution);
        WorkLogEntry.SetRange(Status, WorkLogEntry.Status::Closed);
        if not WorkLogEntry.FindSet() then
            exit;

        repeat
            OperatorTaskKey := WorkLogEntry."Operator Id" + '|' + BuildTaskKey(WorkLogEntry."Order No.", WorkLogEntry."Operation No.", WorkLogEntry."Work Center No.");
            if not ProcessedOperatorTasks.ContainsKey(OperatorTaskKey) then begin
                Seconds := CalculateOperatorTaskSeconds(WorkLogEntry."Operator Id", WorkLogEntry."Order No.", WorkLogEntry."Operation No.", WorkLogEntry."Work Center No.");
                InsertAttribution(AttributionType::Operator, WorkLogEntry."Order No.", WorkLogEntry."Operation No.", WorkLogEntry."Work Center No.", WorkLogEntry."Operator Id", Seconds, CountOperatorTaskIntervals(WorkLogEntry."Operator Id", WorkLogEntry."Order No.", WorkLogEntry."Operation No.", WorkLogEntry."Work Center No."));
                ProcessedOperatorTasks.Add(OperatorTaskKey, true);
            end;
        until WorkLogEntry.Next() = 0;
    end;

    local procedure CalculateMachineSeconds(OrderNo: Code[20]; OperationNo: Code[10]; WorkCenterNo: Code[20]): Decimal
    var
        Boundaries: List of [DateTime];
        SegmentStart: DateTime;
        SegmentEnd: DateTime;
        Seconds: Decimal;
    begin
        CollectTaskBoundaries(OrderNo, OperationNo, WorkCenterNo, Boundaries);

        SegmentStart := GetMinBoundary(Boundaries);
        while SegmentStart <> 0DT do begin
            SegmentEnd := GetNextBoundary(Boundaries, SegmentStart);
            if SegmentEnd = 0DT then
                exit(Seconds);

            if HasActiveTaskSegment(OrderNo, OperationNo, WorkCenterNo, SegmentStart, SegmentEnd) then
                Seconds += DurationSeconds(SegmentStart, SegmentEnd);
            SegmentStart := SegmentEnd;
        end;

        exit(Seconds);
    end;

    local procedure CalculateOperatorTaskSeconds(OperatorId: Code[20]; OrderNo: Code[20]; OperationNo: Code[10]; WorkCenterNo: Code[20]): Decimal
    var
        Boundaries: List of [DateTime];
        ActiveTaskCount: Integer;
        SegmentStart: DateTime;
        SegmentEnd: DateTime;
        Seconds: Decimal;
    begin
        CollectOperatorBoundaries(OperatorId, Boundaries);

        SegmentStart := GetMinBoundary(Boundaries);
        while SegmentStart <> 0DT do begin
            SegmentEnd := GetNextBoundary(Boundaries, SegmentStart);
            if SegmentEnd = 0DT then
                exit(Seconds);

            if HasActiveOperatorTaskSegment(OperatorId, OrderNo, OperationNo, WorkCenterNo, SegmentStart, SegmentEnd) then begin
                ActiveTaskCount := CountActiveOperatorTasks(OperatorId, SegmentStart, SegmentEnd);
                if ActiveTaskCount > 0 then
                    Seconds += DurationSeconds(SegmentStart, SegmentEnd) / ActiveTaskCount;
            end;
            SegmentStart := SegmentEnd;
        end;

        exit(Seconds);
    end;

    local procedure CollectTaskBoundaries(OrderNo: Code[20]; OperationNo: Code[10]; WorkCenterNo: Code[20]; var Boundaries: List of [DateTime])
    var
        WorkLogEntry: Record "ALP Work Log Entry";
    begin
        SetClosedExecutionTaskFilters(WorkLogEntry, OrderNo, OperationNo, WorkCenterNo);
        if WorkLogEntry.FindSet() then
            repeat
                AddBoundary(Boundaries, WorkLogEntry."Start Time");
                AddBoundary(Boundaries, WorkLogEntry."End Time");
            until WorkLogEntry.Next() = 0;
    end;

    local procedure CollectOperatorBoundaries(OperatorId: Code[20]; var Boundaries: List of [DateTime])
    var
        WorkLogEntry: Record "ALP Work Log Entry";
    begin
        WorkLogEntry.SetRange("Event Type", WorkLogEntry."Event Type"::Execution);
        WorkLogEntry.SetRange(Status, WorkLogEntry.Status::Closed);
        WorkLogEntry.SetRange("Operator Id", OperatorId);
        if WorkLogEntry.FindSet() then
            repeat
                AddBoundary(Boundaries, WorkLogEntry."Start Time");
                AddBoundary(Boundaries, WorkLogEntry."End Time");
            until WorkLogEntry.Next() = 0;
    end;

    local procedure HasActiveTaskSegment(OrderNo: Code[20]; OperationNo: Code[10]; WorkCenterNo: Code[20]; SegmentStart: DateTime; SegmentEnd: DateTime): Boolean
    var
        WorkLogEntry: Record "ALP Work Log Entry";
    begin
        SetClosedExecutionTaskFilters(WorkLogEntry, OrderNo, OperationNo, WorkCenterNo);
        WorkLogEntry.SetFilter("Start Time", '<%1', SegmentEnd);
        WorkLogEntry.SetFilter("End Time", '>%1', SegmentStart);
        exit(WorkLogEntry.FindFirst());
    end;

    local procedure HasActiveOperatorTaskSegment(OperatorId: Code[20]; OrderNo: Code[20]; OperationNo: Code[10]; WorkCenterNo: Code[20]; SegmentStart: DateTime; SegmentEnd: DateTime): Boolean
    var
        WorkLogEntry: Record "ALP Work Log Entry";
    begin
        SetClosedExecutionTaskFilters(WorkLogEntry, OrderNo, OperationNo, WorkCenterNo);
        WorkLogEntry.SetRange("Operator Id", OperatorId);
        WorkLogEntry.SetFilter("Start Time", '<%1', SegmentEnd);
        WorkLogEntry.SetFilter("End Time", '>%1', SegmentStart);
        exit(WorkLogEntry.FindFirst());
    end;

    local procedure CountActiveOperatorTasks(OperatorId: Code[20]; SegmentStart: DateTime; SegmentEnd: DateTime): Integer
    var
        WorkLogEntry: Record "ALP Work Log Entry";
        ActiveTasks: Dictionary of [Text, Boolean];
        TaskKey: Text;
    begin
        WorkLogEntry.SetRange("Event Type", WorkLogEntry."Event Type"::Execution);
        WorkLogEntry.SetRange(Status, WorkLogEntry.Status::Closed);
        WorkLogEntry.SetRange("Operator Id", OperatorId);
        WorkLogEntry.SetFilter("Start Time", '<%1', SegmentEnd);
        WorkLogEntry.SetFilter("End Time", '>%1', SegmentStart);
        if WorkLogEntry.FindSet() then
            repeat
                TaskKey := BuildTaskKey(WorkLogEntry."Order No.", WorkLogEntry."Operation No.", WorkLogEntry."Work Center No.");
                if not ActiveTasks.ContainsKey(TaskKey) then
                    ActiveTasks.Add(TaskKey, true);
            until WorkLogEntry.Next() = 0;

        exit(ActiveTasks.Count());
    end;

    local procedure SetClosedExecutionTaskFilters(var WorkLogEntry: Record "ALP Work Log Entry"; OrderNo: Code[20]; OperationNo: Code[10]; WorkCenterNo: Code[20])
    begin
        WorkLogEntry.SetRange("Event Type", WorkLogEntry."Event Type"::Execution);
        WorkLogEntry.SetRange(Status, WorkLogEntry.Status::Closed);
        WorkLogEntry.SetRange("Order No.", OrderNo);
        WorkLogEntry.SetRange("Operation No.", OperationNo);
        WorkLogEntry.SetRange("Work Center No.", WorkCenterNo);
    end;

    local procedure CountTaskIntervals(OrderNo: Code[20]; OperationNo: Code[10]; WorkCenterNo: Code[20]): Integer
    var
        WorkLogEntry: Record "ALP Work Log Entry";
    begin
        SetClosedExecutionTaskFilters(WorkLogEntry, OrderNo, OperationNo, WorkCenterNo);
        exit(WorkLogEntry.Count());
    end;

    local procedure CountOperatorTaskIntervals(OperatorId: Code[20]; OrderNo: Code[20]; OperationNo: Code[10]; WorkCenterNo: Code[20]): Integer
    var
        WorkLogEntry: Record "ALP Work Log Entry";
    begin
        SetClosedExecutionTaskFilters(WorkLogEntry, OrderNo, OperationNo, WorkCenterNo);
        WorkLogEntry.SetRange("Operator Id", OperatorId);
        exit(WorkLogEntry.Count());
    end;

    local procedure AddBoundary(var Boundaries: List of [DateTime]; Boundary: DateTime)
    begin
        if Boundary = 0DT then
            exit;

        if not Boundaries.Contains(Boundary) then
            Boundaries.Add(Boundary);
    end;

    local procedure GetMinBoundary(Boundaries: List of [DateTime]): DateTime
    var
        Boundary: DateTime;
        MinBoundary: DateTime;
    begin
        foreach Boundary in Boundaries do
            if (MinBoundary = 0DT) or (Boundary < MinBoundary) then
                MinBoundary := Boundary;

        exit(MinBoundary);
    end;

    local procedure GetNextBoundary(Boundaries: List of [DateTime]; CurrentBoundary: DateTime): DateTime
    var
        Boundary: DateTime;
        NextBoundary: DateTime;
    begin
        foreach Boundary in Boundaries do
            if Boundary > CurrentBoundary then
                if (NextBoundary = 0DT) or (Boundary < NextBoundary) then
                    NextBoundary := Boundary;

        exit(NextBoundary);
    end;

    local procedure DurationSeconds(StartTime: DateTime; EndTime: DateTime): Decimal
    var
        DurationMs: BigInteger;
    begin
        DurationMs := EndTime - StartTime;
        if DurationMs <= 0 then
            exit(0);

        exit(DurationMs / 1000);
    end;

    local procedure InsertAttribution(AttributionType: Enum "ALP Time Attribution Type"; OrderNo: Code[20]; OperationNo: Code[10]; WorkCenterNo: Code[20]; OperatorId: Code[20]; Seconds: Decimal; IntervalCount: Integer)
    var
        Attribution: Record "ALP Execution Time Attribution";
    begin
        if Seconds <= 0 then
            exit;

        Attribution.Init();
        Attribution."Attribution Type" := AttributionType;
        Attribution."Order No." := OrderNo;
        Attribution."Operation No." := OperationNo;
        Attribution."Work Center No." := WorkCenterNo;
        Attribution."Operator Id" := OperatorId;
        Attribution."Attributed Seconds" := Seconds;
        Attribution."Interval Count" := IntervalCount;
        Attribution."Calculated At" := CurrentDateTime();
        Attribution.Insert(true);
    end;

    local procedure BuildTaskKey(OrderNo: Code[20]; OperationNo: Code[10]; WorkCenterNo: Code[20]): Text
    begin
        exit(OrderNo + '|' + OperationNo + '|' + WorkCenterNo);
    end;
}
