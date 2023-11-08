![image](https://github.com/kevinnwhenn/Kevin-Portfolio/assets/109677078/1721ac6c-076a-46ce-af87-86c49d154eb8)


```sql
--SQL VIEW--
CREATE VIEW [dbo].[CycleCountProgression_view]
AS 

SELECT
	'53' AS Total_Count_Days_Scheduled,
	COUNT(DISTINCT tb.Bin) AS Total_Bins,
	(SELECT
		SUM(total.Daily_Total_Bins_Counted) AS Daily_Total_Bins_Counted
	FROM
	(
	SELECT
		CONVERT(date, tcch.DateTime) AS Date,
		COUNT(DISTINCT tcch.Bin) AS Daily_Total_Bins_Counted
	FROM
		WarehouseCompany1.dbo.tblCycleCountHistory tcch
	LEFT JOIN WarehouseCompany1.dbo.tblBin tb ON tb.Bin = tcch.Bin
	WHERE
		tb.Warehouse = '01'
		AND MONTH(tcch.DateTime) IN (10,11,12)
		AND YEAR(tcch.DateTime) = YEAR(GETDATE())
		AND tb.bLevel = 'Remove from Grid'
	GROUP BY
		CONVERT(date, tcch.DateTime)
		) AS total) AS Total_Bins_Counted,
	COUNT(DISTINCT tb.Bin)
		-(SELECT
		SUM(total.Daily_Total_Bins_Counted) AS Daily_Total_Bins_Counted
	FROM
	(
	SELECT
		CONVERT(date, tcch.DateTime) AS Date,
		COUNT(DISTINCT tcch.Bin) AS Daily_Total_Bins_Counted
	FROM
		WarehouseCompany1.dbo.tblCycleCountHistory tcch
	LEFT JOIN WarehouseCompany1.dbo.tblBin tb ON tb.Bin = tcch.Bin
	WHERE
		tb.Warehouse = '01'
		AND MONTH(tcch.DateTime) IN (10,11,12)
		AND YEAR(tcch.DateTime) = YEAR(GETDATE())
		AND tb.bLevel = 'Remove from Grid'
	GROUP BY
		CONVERT(date, tcch.DateTime)
		) AS total) AS Total_Bins_Not_Counted,
	(SELECT
		SUM(total.Daily_Datascope_Value) AS Daily_Datascope_Value
	FROM
	(
	SELECT
		CONVERT(date, tcch.DateTime) AS Date,
		SUM(tcch.UnitCostPrice * tcch.WMSSOH) AS Daily_Datascope_Value
	FROM
		WarehouseCompany1.dbo.tblCycleCountHistory tcch
	LEFT JOIN WarehouseCompany1.dbo.tblBin tb ON tb.Bin = tcch.Bin
	WHERE
		tb.Warehouse = '01'
		AND MONTH(tcch.DateTime) IN (10,11,12)
		AND YEAR(tcch.DateTime) = YEAR(GETDATE())
		AND tb.bLevel = 'Remove from Grid'
	GROUP BY
		CONVERT(date, tcch.DateTime)
	) AS total) AS Running_$_Counted,
	(
	SELECT
		SUM(total.Daily_Net_Adjustments) AS Daily_Net_Adjustments
	FROM
	(
	SELECT
		CONVERT(date, tcch.DateTime) AS Date,
		(SUM(tcch.UnitCostPrice * tcch.CapturedQty) - SUM(tcch.UnitCostPrice * tcch.WMSSOH)) AS Daily_Net_Adjustments
	FROM
		WarehouseCompany1.dbo.tblCycleCountHistory tcch
	LEFT JOIN WarehouseCompany1.dbo.tblBin tb ON tb.Bin = tcch.Bin
	WHERE
		tb.Warehouse = '01'
		AND MONTH(tcch.DateTime) IN (10,11,12)
		AND YEAR(tcch.DateTime) = YEAR(GETDATE())
		AND tb.bLevel = 'Remove from Grid'
	GROUP BY
		CONVERT(date, tcch.DateTime)
	) AS total) AS Running_Net_Adjustments
FROM
	WarehouseCompany1.dbo.tblBin tb
WHERE
	tb.Warehouse = '01'
	AND tb.bLevel = 'Remove from Grid'

GO

--SQL Stored Procedure--

CREATE PROCEDURE [dbo].[CycleCountProgression]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT * FROM [dbo].[CycleCountProgression_view]
END
GO
