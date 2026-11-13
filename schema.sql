/*
  Smart Todo database schema for Microsoft SQL Server.
  API field mapping:
    due_date     -> dueDate
    is_completed -> isCompleted
    created_at   -> createdAt
    updated_at   -> updatedAt
*/

IF DB_ID(N'SmartTodoDb') IS NULL
BEGIN
    CREATE DATABASE SmartTodoDb;
END;
GO

USE SmartTodoDb;
GO

IF OBJECT_ID(N'dbo.tasks', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.tasks (
        id           INT IDENTITY(1,1) NOT NULL,
        title        NVARCHAR(200) NOT NULL,
        description  NVARCHAR(1000) NULL,
        priority     NVARCHAR(10) NOT NULL,
        due_date     DATE NOT NULL,
        is_completed BIT NOT NULL
            CONSTRAINT DF_tasks_is_completed DEFAULT (0),
        created_at   DATETIME2(3) NOT NULL
            CONSTRAINT DF_tasks_created_at DEFAULT (SYSUTCDATETIME()),
        updated_at   DATETIME2(3) NOT NULL
            CONSTRAINT DF_tasks_updated_at DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_tasks PRIMARY KEY CLUSTERED (id),
        CONSTRAINT CK_tasks_title_not_blank
            CHECK (LEN(LTRIM(RTRIM(title))) > 0),
        CONSTRAINT CK_tasks_priority
            CHECK (priority IN (N'low', N'medium', N'high'))
    );

    -- Supports filtering tasks by status/priority and ordering by id.
    CREATE INDEX IX_tasks_status_priority_id
        ON dbo.tasks (is_completed, priority, id);
END;
GO

/*
  On successful PUT, the API must set updated_at to SYSUTCDATETIME().
  SQL Server does not automatically update this column when a row changes.
  Serialize DATETIME2 values as ISO 8601 UTC timestamps and DATE as YYYY-MM-DD.
*/
