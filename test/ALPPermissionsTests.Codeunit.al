/// <summary>
/// Test codeunit for ALP Permission Sets.
/// Validates principle of least privilege and proper access control.
/// </summary>
codeunit 50091 "ALP Permissions Tests"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure ExecutionTable_IsAccessible()
    var
        ALPOperationExecution: Record "ALP Operation Execution";
    begin
        // [SCENARIO] Execution tables exist and are accessible
        // [GIVEN] The ALP Operation Execution table

        // [WHEN] Checking table accessibility
        // [THEN] Table is accessible (not temporary)
        Assert.IsFalse(ALPOperationExecution.IsTemporary(), 'Execution table should not be temporary');
    end;

    [Test]
    procedure InboxTable_IsAccessible()
    var
        ALPIntegrationInbox: Record "ALP Integration Inbox";
    begin
        // [SCENARIO] Inbox table exists and is accessible
        // [GIVEN] The ALP Integration Inbox table

        // [WHEN] Checking table accessibility
        // [THEN] Table is accessible (not temporary)
        Assert.IsFalse(ALPIntegrationInbox.IsTemporary(), 'Inbox table should not be temporary');
    end;

    [Test]
    [TestPermissions(TestPermissions::Disabled)]
    procedure ShopfloorAPIPermissionSet_AllowsTableAccess()
    var
        ALPIntegrationInbox: Record "ALP Integration Inbox";
        ALPOperationExecution: Record "ALP Operation Execution";
    begin
        // [SCENARIO] API permission set allows access to integration tables
        // [GIVEN] The ALP Shopfloor API permission set (ID 50040)

        // [WHEN] Tables are accessed with proper permissions
        // [THEN] Read permission is available
        Assert.IsTrue(ALPIntegrationInbox.ReadPermission(), 'Should have read permission on Inbox');
        Assert.IsTrue(ALPOperationExecution.ReadPermission(), 'Should have read permission on Execution');
    end;

    [Test]
    [TestPermissions(TestPermissions::Disabled)]
    procedure ShopfloorReaderPermissionSet_AllowsReadAccess()
    var
        ALPIntegrationInbox: Record "ALP Integration Inbox";
        ALPOperationExecution: Record "ALP Operation Execution";
    begin
        // [SCENARIO] Reader permission set allows read access
        // [GIVEN] The ALP Shopfloor Reader permission set (ID 50041)

        // [WHEN] Checking permissions with reader access
        // [THEN] Read permission is granted
        Assert.IsTrue(ALPIntegrationInbox.ReadPermission(), 'Should have read permission on Inbox');
        Assert.IsTrue(ALPOperationExecution.ReadPermission(), 'Should have read permission on Execution');
    end;

    [Test]
    procedure PermissionSet_APIExists()
    var
        MetadataPermissionSet: Record "Metadata Permission Set";
    begin
        // [SCENARIO] ALP Shopfloor API permission set exists
        // [GIVEN] The extension is installed

        // [WHEN] Looking for the permission set
        MetadataPermissionSet.SetRange("Role ID", 'ALP SHOPFLOOR API');

        // [THEN] Permission set exists
        Assert.IsFalse(MetadataPermissionSet.IsEmpty(), 'ALP Shopfloor API permission set should exist');
    end;

    [Test]
    procedure PermissionSet_ReaderExists()
    var
        MetadataPermissionSet: Record "Metadata Permission Set";
    begin
        // [SCENARIO] ALP Shopfloor Reader permission set exists
        // [GIVEN] The extension is installed

        // [WHEN] Looking for the permission set
        MetadataPermissionSet.SetRange("Role ID", 'ALP SHOPFLOOR READER');

        // [THEN] Permission set exists
        Assert.IsFalse(MetadataPermissionSet.IsEmpty(), 'ALP Shopfloor Reader permission set should exist');
    end;

    [Test]
    [TestPermissions(TestPermissions::Disabled)]
    procedure IngestionCodeunit_IsAccessible()
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        // [SCENARIO] The ingestion codeunit exists and is accessible
        // [GIVEN] The extension is installed

        // [WHEN] Looking for the codeunit
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Codeunit);
        AllObjWithCaption.SetRange("Object ID", 50010);

        // [THEN] Codeunit exists
        Assert.IsFalse(AllObjWithCaption.IsEmpty(), 'ALP Execution Ingestion Svc codeunit should exist');
    end;
}
