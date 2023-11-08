```sql
--SQL VIEW--
CREATE VIEW [dbo].[CycleCountVariance_view]
AS 

SELECT
	CONVERT(date, tcch.DateTime) AS Date,
	COUNT(DISTINCT tcch.Bin) AS Daily_Total_Bins_Counted,
	(
	SELECT
		COUNT(DISTINCT tb.Bin) AS Total_Bins
	FROM
		WarehouseCompany1.dbo.tblBin tb
	WHERE
		tb.Warehouse = '01'
		AND tb.bLevel = 'Remove from Grid'	
	) AS Total_Bins,
	SUM(tcch.UnitCostPrice * tcch.WMSSOH) AS Daily_Datascope_Value,
	(SUM(tcch.UnitCostPrice * tcch.CapturedQty) - SUM(tcch.UnitCostPrice * tcch.WMSSOH)) AS Daily_Net_Adjustments,
	CAST(CAST(((SUM(tcch.UnitCostPrice * tcch.CapturedQty) - SUM(tcch.UnitCostPrice * tcch.WMSSOH))/SUM(tcch.UnitCostPrice * tcch.WMSSOH))*100 AS DECIMAL(18,2)) AS VARCHAR(6)) + '%' AS Daily_Variance,
	((DATEDIFF(dd, CONVERT(date, tcch.DateTime), '2023-12-15') + 1)  
   	-(DATEDIFF(wk, CONVERT(date, tcch.DateTime), '2023-12-15') * 2)  
   	-(CASE WHEN DATENAME(dw, CONVERT(date, tcch.DateTime)) = 'Sunday' THEN 1 ELSE 0 END)  
   	-(CASE WHEN DATENAME(dw, CONVERT(date, tcch.DateTime)) = 'Saturday' THEN 1 ELSE 0 END))-3 AS Count_Days_Remaining,
	((SELECT COUNT(DISTINCT tblBin.Bin) AS Total_Bins FROM WarehouseCompany1.dbo.tblBin WHERE Warehouse = '01' AND bLevel = 'Remove from Grid')-COUNT(DISTINCT tcch.Bin))/(((DATEDIFF(dd, CONVERT(date, tcch.DateTime), '2023-12-15') + 1)  
   	-(DATEDIFF(wk, CONVERT(date, tcch.DateTime), '2023-12-15') * 2)  
   	-(CASE WHEN DATENAME(dw, CONVERT(date, tcch.DateTime)) = 'Sunday' THEN 1 ELSE 0 END)  
   	-(CASE WHEN DATENAME(dw, CONVERT(date, tcch.DateTime)) = 'Saturday' THEN 1 ELSE 0 END))-3) AS Average_Number_Of_Bins_Per_Count
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

GO

--SQL Stored Procedure--

CREATE PROCEDURE [dbo].[CycleCountVariance]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT * FROM [dbo].[CycleCountVariance_view]
END
GO
