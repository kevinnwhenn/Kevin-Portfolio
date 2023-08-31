### Daily Cycle Count Report
- The purpose of this report is to monitor daily cycle counts vs. active bins that have not been cycle counted. This will give us the visibility of what has been counted and needs to be counted with $value of the Inventory.

```sql
--SQL VIEW--
CREATE VIEW [dbo].[CycleCount_view]
AS 

SELECT
	tcch.Bin,
	tcch.StockCode,
	im.Description,
	tcch.CapturedQty,
	(tcch.UnitCostPrice * tcch.CapturedQty) AS CapturedValue,
	tcch.WMSSOH,
	(tcch.UnitCostPrice * tcch.WMSSOH) AS WMSValue,
	tcch.SysproSOH,
	(tcch.UnitCostPrice * tcch.SysproSOH) AS SysproValue,
	CONVERT(date, tcch.DateTime) AS Date,
	(
	SELECT
		COUNT(DISTINCT tcch.Bin)
	FROM
		WarehouseDatabase.dbo.CycleCount tcch
	LEFT JOIN WarehouseDatabase.dbo.tblBin tb ON tb.Bin = tcch.Bin
	WHERE
		tb.Warehouse = '01') AS TotalBins
FROM
	WarehouseDatabase.dbo.CycleCount tcch WITH(NOLOCK)
LEFT JOIN WarehouseCompany1.dbo.tblBin tb WITH(NOLOCK) ON tb.Bin = tcch.Bin
LEFT JOIN Database.dbo.Inventory im WITH(NOLOCK) ON im.StockCode = tcch.StockCode
WHERE
	tb.Warehouse = '01'

GO

--SQL Stored Procedure--
CREATE PROCEDURE [dbo].[CycleCount] 
	@Date Date
AS
BEGIN
	SET NOCOUNT ON;

SELECT * FROM [dbo].[CycleCount_view] WHERE [Date] = @Date
END
GO
