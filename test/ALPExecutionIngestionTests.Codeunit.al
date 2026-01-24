/// <summary>
/// Test codeunit for ALP Execution Ingestion Service.
/// Validates safety, idempotency, and resilience of execution event processing.
/// </summary>
codeunit 50090 "ALP Execution Ingestion Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        IsInitialized: Boolean;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
        Commit();
    end;

    local procedure CreateReleasedProductionOrder(var ProductionOrder: Record "Production Order")
    var
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        // Create a simple item using library
        LibraryInventory.CreateItem(Item);

        // Create and release production order
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder,
            ProductionOrder.Status::Released,
            ProductionOrder."Source Type"::Item,
            Item."No.",
            LibraryRandom.RandInt(10));
    end;

    local procedure CreateExecutionRecord(OrderNo: Code[20]; OperationNo: Code[10]; Parts: Integer; Rejected: Integer; Availability: Decimal; Productivity: Decimal; SourceTimestamp: DateTime): Record "ALP Operation Execution"
    var
        Exec: Record "ALP Operation Execution";
    begin
        Exec.Init();
        Exec."Order No." := OrderNo;
        Exec."Operation No." := OperationNo;
        Exec."Work Center No." := 'WC001';
        Exec."nParts" := Parts;
        Exec."nRejected" := Rejected;
        Exec."Runtime Sec" := 3600;
        Exec."Downtime Sec" := 600;
        Exec.Availability := Availability;
        Exec.Productivity := Productivity;
        Exec."Source Timestamp" := SourceTimestamp;
        Exec.Source := 'SHOPFLOOR';
        exit(Exec);
    end;

    local procedure CleanupTestData(MessageId: Guid; OrderNo: Code[20]; OperationNo: Code[10])
    var
        ALPIntegrationInbox: Record "ALP Integration Inbox";
        ALPOperationExecution: Record "ALP Operation Execution";
    begin
        if ALPIntegrationInbox.Get(MessageId) then
            ALPIntegrationInbox.Delete(true);

        if ALPOperationExecution.Get(OrderNo, OperationNo) then
            ALPOperationExecution.Delete(true);
    end;

    [Test]
    procedure ValidExecutionIngestion_CreatesOneRecord()
    var
        ProductionOrder: Record "Production Order";
        ALPIntegrationInbox: Record "ALP Integration Inbox";
        ALPOperationExecution: Record "ALP Operation Execution";
        Exec: Record "ALP Operation Execution";
        ALPExecutionIngestionSvc: Codeunit "ALP Execution Ingestion Svc";
        MessageId: Guid;
        OperationNo: Code[10];
        Result: Boolean;
    begin
        // [SCENARIO] Valid execution payload creates exactly one execution record
        Initialize();

        // [GIVEN] A released Production Order
        CreateReleasedProductionOrder(ProductionOrder);
        OperationNo := '10';

        // [GIVEN] A valid execution payload
        MessageId := CreateGuid();
        Exec := CreateExecutionRecord(ProductionOrder."No.", OperationNo, 100, 5, 0.85, 0.90, CurrentDateTime);

        // [WHEN] The ingestion codeunit is called
        Result := ALPExecutionIngestionSvc.ProcessExecutionEvent(Exec, MessageId);

        // [THEN] Function returns true (success)
        Assert.IsTrue(Result, 'ProcessExecutionEvent should return true');

        // [THEN] One execution record exists
        ALPOperationExecution.SetRange("Order No.", ProductionOrder."No.");
        ALPOperationExecution.SetRange("Operation No.", OperationNo);
        Assert.RecordCount(ALPOperationExecution, 1);

        // [THEN] Inbox entry is marked Processed
        Assert.IsTrue(ALPIntegrationInbox.Get(MessageId), 'Inbox entry should exist');
        Assert.AreEqual(
            ALPIntegrationInbox.Status::Processed,
            ALPIntegrationInbox.Status,
            'Inbox status should be Processed');

        // [THEN] Execution record has correct values
        ALPOperationExecution.Get(ProductionOrder."No.", OperationNo);
        Assert.AreEqual(100, ALPOperationExecution."nParts", 'Parts count mismatch');
        Assert.AreEqual(5, ALPOperationExecution."nRejected", 'Rejected count mismatch');

        // Cleanup
        CleanupTestData(MessageId, ProductionOrder."No.", OperationNo);
    end;

    [Test]
    procedure Idempotency_DuplicateMessageId_CreatesOnlyOneRecord()
    var
        ProductionOrder: Record "Production Order";
        ALPIntegrationInbox: Record "ALP Integration Inbox";
        ALPOperationExecution: Record "ALP Operation Execution";
        Exec1: Record "ALP Operation Execution";
        Exec2: Record "ALP Operation Execution";
        ALPExecutionIngestionSvc: Codeunit "ALP Execution Ingestion Svc";
        MessageId: Guid;
        OperationNo: Code[10];
        Result1: Boolean;
        Result2: Boolean;
    begin
        // [SCENARIO] Same payload with same MessageId ingested twice creates only one record
        Initialize();

        // [GIVEN] A released Production Order
        CreateReleasedProductionOrder(ProductionOrder);
        OperationNo := '10';

        // [GIVEN] Same MessageId for both calls
        MessageId := CreateGuid();

        // [WHEN] Ingestion is called first time
        Exec1 := CreateExecutionRecord(ProductionOrder."No.", OperationNo, 100, 5, 0.85, 0.90, CurrentDateTime);
        Result1 := ALPExecutionIngestionSvc.ProcessExecutionEvent(Exec1, MessageId);

        // [WHEN] Ingestion is called second time with same MessageId
        Exec2 := CreateExecutionRecord(ProductionOrder."No.", OperationNo, 200, 10, 0.75, 0.80, CurrentDateTime);
        Result2 := ALPExecutionIngestionSvc.ProcessExecutionEvent(Exec2, MessageId);

        // [THEN] Both calls return true (no exception thrown)
        Assert.IsTrue(Result1, 'First call should succeed');
        Assert.IsTrue(Result2, 'Second call should succeed (idempotent)');

        // [THEN] Only one execution record exists
        ALPOperationExecution.SetRange("Order No.", ProductionOrder."No.");
        ALPOperationExecution.SetRange("Operation No.", OperationNo);
        Assert.RecordCount(ALPOperationExecution, 1);

        // [THEN] Inbox contains only one entry
        ALPIntegrationInbox.SetRange("Message Id", MessageId);
        Assert.RecordCount(ALPIntegrationInbox, 1);

        // [THEN] Values from first call are preserved (not overwritten by duplicate)
        ALPOperationExecution.Get(ProductionOrder."No.", OperationNo);
        Assert.AreEqual(100, ALPOperationExecution."nParts", 'Original parts count should be preserved');

        // Cleanup
        CleanupTestData(MessageId, ProductionOrder."No.", OperationNo);
    end;

    [Test]
    procedure OutOfOrderProtection_OlderTimestamp_IsIgnored()
    var
        ProductionOrder: Record "Production Order";
        ALPOperationExecution: Record "ALP Operation Execution";
        Exec1: Record "ALP Operation Execution";
        Exec2: Record "ALP Operation Execution";
        ALPExecutionIngestionSvc: Codeunit "ALP Execution Ingestion Svc";
        MessageId1: Guid;
        MessageId2: Guid;
        NewerTimestamp: DateTime;
        OlderTimestamp: DateTime;
        OperationNo: Code[10];
    begin
        // [SCENARIO] Execution event with older timestamp does not overwrite newer data
        Initialize();

        // [GIVEN] A released Production Order
        CreateReleasedProductionOrder(ProductionOrder);
        OperationNo := '10';

        // [GIVEN] Execution event with newer timestamp
        MessageId1 := CreateGuid();
        NewerTimestamp := CurrentDateTime;

        // [GIVEN] Execution event with older timestamp
        MessageId2 := CreateGuid();
        OlderTimestamp := NewerTimestamp - 3600000;  // 1 hour earlier

        // [WHEN] Newer event is ingested first
        Exec1 := CreateExecutionRecord(ProductionOrder."No.", OperationNo, 200, 10, 0.90, 0.95, NewerTimestamp);
        ALPExecutionIngestionSvc.ProcessExecutionEvent(Exec1, MessageId1);

        // [WHEN] Older event is ingested second (out of order)
        Exec2 := CreateExecutionRecord(ProductionOrder."No.", OperationNo, 100, 5, 0.80, 0.85, OlderTimestamp);
        ALPExecutionIngestionSvc.ProcessExecutionEvent(Exec2, MessageId2);

        // [THEN] Stored execution reflects the newer event only
        ALPOperationExecution.Get(ProductionOrder."No.", OperationNo);
        Assert.AreEqual(NewerTimestamp, ALPOperationExecution."Source Timestamp", 'Source timestamp should be unchanged');
        Assert.AreEqual(200, ALPOperationExecution."nParts", 'Newer parts value should be preserved');
        Assert.AreEqual(0.90, ALPOperationExecution.Availability, 'Newer availability should be preserved');

        // Cleanup
        CleanupTestData(MessageId1, ProductionOrder."No.", OperationNo);
        CleanupTestData(MessageId2, ProductionOrder."No.", OperationNo);
    end;

    [Test]
    procedure InvalidInput_RejectedGreaterThanParts_ReturnsFalse()
    var
        ProductionOrder: Record "Production Order";
        ALPIntegrationInbox: Record "ALP Integration Inbox";
        ALPOperationExecution: Record "ALP Operation Execution";
        Exec: Record "ALP Operation Execution";
        ALPExecutionIngestionSvc: Codeunit "ALP Execution Ingestion Svc";
        MessageId: Guid;
        OperationNo: Code[10];
        Result: Boolean;
    begin
        // [SCENARIO] Ingestion fails when nRejected > nParts
        Initialize();

        // [GIVEN] A released Production Order
        CreateReleasedProductionOrder(ProductionOrder);
        OperationNo := '10';

        // [GIVEN] nRejected > nParts (invalid)
        MessageId := CreateGuid();
        Exec := CreateExecutionRecord(ProductionOrder."No.", OperationNo, 100, 150, 0.85, 0.90, CurrentDateTime);  // 150 > 100

        // [WHEN] Ingestion is attempted
        Result := ALPExecutionIngestionSvc.ProcessExecutionEvent(Exec, MessageId);

        // [THEN] Function returns false
        Assert.IsFalse(Result, 'ProcessExecutionEvent should return false for invalid input');

        // [THEN] No execution record created
        ALPOperationExecution.SetRange("Order No.", ProductionOrder."No.");
        ALPOperationExecution.SetRange("Operation No.", OperationNo);
        Assert.RecordIsEmpty(ALPOperationExecution);

        // [THEN] Inbox entry is marked Failed
        Assert.IsTrue(ALPIntegrationInbox.Get(MessageId), 'Inbox entry should exist');
        Assert.AreEqual(
            ALPIntegrationInbox.Status::Failed,
            ALPIntegrationInbox.Status,
            'Inbox status should be Failed');

        // Cleanup
        CleanupTestData(MessageId, ProductionOrder."No.", OperationNo);
    end;

    [Test]
    procedure InvalidInput_AvailabilityOutOfRange_ReturnsFalse()
    var
        ProductionOrder: Record "Production Order";
        ALPIntegrationInbox: Record "ALP Integration Inbox";
        Exec: Record "ALP Operation Execution";
        ALPExecutionIngestionSvc: Codeunit "ALP Execution Ingestion Svc";
        MessageId: Guid;
        OperationNo: Code[10];
        Result: Boolean;
    begin
        // [SCENARIO] Ingestion fails when availability is outside 0-1 range
        Initialize();

        // [GIVEN] A released Production Order
        CreateReleasedProductionOrder(ProductionOrder);
        OperationNo := '10';

        // [GIVEN] Availability > 1 (invalid)
        MessageId := CreateGuid();
        Exec := CreateExecutionRecord(ProductionOrder."No.", OperationNo, 100, 5, 1.5, 0.90, CurrentDateTime);

        // [WHEN] Ingestion is attempted
        Result := ALPExecutionIngestionSvc.ProcessExecutionEvent(Exec, MessageId);

        // [THEN] Function returns false
        Assert.IsFalse(Result, 'ProcessExecutionEvent should return false for availability > 1');

        // [THEN] Inbox entry is marked Failed
        Assert.IsTrue(ALPIntegrationInbox.Get(MessageId), 'Inbox entry should exist');
        Assert.AreEqual(
            ALPIntegrationInbox.Status::Failed,
            ALPIntegrationInbox.Status,
            'Inbox status should be Failed');

        // Cleanup
        CleanupTestData(MessageId, ProductionOrder."No.", OperationNo);
    end;

    [Test]
    procedure InvalidInput_ProductivityOutOfRange_ReturnsFalse()
    var
        ProductionOrder: Record "Production Order";
        ALPIntegrationInbox: Record "ALP Integration Inbox";
        Exec: Record "ALP Operation Execution";
        ALPExecutionIngestionSvc: Codeunit "ALP Execution Ingestion Svc";
        MessageId: Guid;
        OperationNo: Code[10];
        Result: Boolean;
    begin
        // [SCENARIO] Ingestion fails when productivity is outside 0-1 range
        Initialize();

        // [GIVEN] A released Production Order
        CreateReleasedProductionOrder(ProductionOrder);
        OperationNo := '10';

        // [GIVEN] Productivity < 0 (invalid)
        MessageId := CreateGuid();
        Exec := CreateExecutionRecord(ProductionOrder."No.", OperationNo, 100, 5, 0.85, -0.1, CurrentDateTime);

        // [WHEN] Ingestion is attempted
        Result := ALPExecutionIngestionSvc.ProcessExecutionEvent(Exec, MessageId);

        // [THEN] Function returns false
        Assert.IsFalse(Result, 'ProcessExecutionEvent should return false for productivity < 0');

        // [THEN] Inbox entry is marked Failed
        Assert.IsTrue(ALPIntegrationInbox.Get(MessageId), 'Inbox entry should exist');
        Assert.AreEqual(
            ALPIntegrationInbox.Status::Failed,
            ALPIntegrationInbox.Status,
            'Inbox status should be Failed');

        // Cleanup
        CleanupTestData(MessageId, ProductionOrder."No.", OperationNo);
    end;

    [Test]
    procedure InvalidInput_ProductionOrderNotReleased_ReturnsFalse()
    var
        ALPIntegrationInbox: Record "ALP Integration Inbox";
        ALPOperationExecution: Record "ALP Operation Execution";
        Exec: Record "ALP Operation Execution";
        ALPExecutionIngestionSvc: Codeunit "ALP Execution Ingestion Svc";
        MessageId: Guid;
        FakeOrderNo: Code[20];
        OperationNo: Code[10];
        Result: Boolean;
    begin
        // [SCENARIO] Ingestion fails when Production Order does not exist or is not Released
        Initialize();

        // [GIVEN] A non-existent Production Order
        FakeOrderNo := 'FAKE-ORDER-999';
        OperationNo := '10';
        MessageId := CreateGuid();
        Exec := CreateExecutionRecord(FakeOrderNo, OperationNo, 100, 5, 0.85, 0.90, CurrentDateTime);

        // [WHEN] Ingestion is attempted
        Result := ALPExecutionIngestionSvc.ProcessExecutionEvent(Exec, MessageId);

        // [THEN] Function returns false
        Assert.IsFalse(Result, 'ProcessExecutionEvent should return false for non-existent order');

        // [THEN] No execution record created
        ALPOperationExecution.SetRange("Order No.", FakeOrderNo);
        Assert.RecordIsEmpty(ALPOperationExecution);

        // [THEN] Inbox entry is marked Failed
        Assert.IsTrue(ALPIntegrationInbox.Get(MessageId), 'Inbox entry should exist');
        Assert.AreEqual(
            ALPIntegrationInbox.Status::Failed,
            ALPIntegrationInbox.Status,
            'Inbox status should be Failed');

        // Cleanup
        CleanupTestData(MessageId, FakeOrderNo, OperationNo);
    end;
}
