### Daily Cycle Count Report
- The purpose of this report is to monitor daily cycle counts vs. active bins that have not been cycle counted. This will give us the visibility of what has been counted and needs to be counted with $value of the Inventory.
- We are wanting to start cycling counting daily to see if our counts line up with the total amount received for the entire year. This way we can determine if we can eliminate the process of doing a big inventory count each year.

```sql
--SQL VIEW--
CREATE VIEW [dbo].[CycleCount_view]
AS 

SELECT
	tb.Bin,
	SUM(counts.CapturedQty) AS CapturedQty,
	SUM(counts.CapturedValue) AS CapturedValue,
	SUM(counts.DataScopeQty) AS DataScopeQty,
	SUM(counts.DataScopeValue) AS DataScopeValue,
	SUM(counts.SysproQty) AS SysproQty,
	SUM(counts.SysproValue) AS SysproValue,
	counts.Date
FROM
	WarehouseCompany1.dbo.tblBin tb
LEFT JOIN (
	SELECT
		tcch.Bin,
		SUM(tcch.CapturedQty) AS CapturedQty,
		SUM(tcch.UnitCostPrice * tcch.CapturedQty) AS CapturedValue,
		SUM(tcch.WMSSOH) AS DataScopeQty,
		SUM(tcch.UnitCostPrice * tcch.WMSSOH) AS DataScopeValue,
		SUM(tcch.SysproSOH) AS SysproQty,
		SUM(tcch.UnitCostPrice * tcch.SysproSOH) AS SysproValue,
		CONVERT(date, tcch.DateTime) AS Date
	FROM
		WarehouseCompany1.dbo.tblCycleCountHistory tcch
	LEFT JOIN WarehouseCompany1.dbo.tblBin tb ON tb.Bin = tcch.Bin
	WHERE
		tb.Warehouse = '01'
		AND YEAR(tcch.DateTime) = YEAR(GETDATE())
	GROUP BY	
		tcch.Bin,
		CONVERT(date, tcch.DateTime)
) AS counts ON counts.Bin = tb.Bin
WHERE
	tb.Warehouse = '01'
	AND tb.bLevel = 'Remove from Grid'
GROUP BY
	tb.Bin,
	counts.Date

GO

--SQL Stored Procedure--
CREATE PROCEDURE [dbo].[CycleCount] 
	@Date Date
AS
BEGIN
	SET NOCOUNT ON;

	SELECT
		*
	FROM
		[dbo].[DailyCycleCountSummary_view]
	WHERE
	(
        (ISNULL(@Quarter, '') <> '' AND DATEPART(q,[DailyCycleCountSummary_view].Date)=@Quarter) OR
        (ISNULL(@Quarter, '') = '')
    );
END
GO
