### Display Vendor Return Rates
- **Question**: Which of our Vendors are returning the most amount of product?
- Return rate is calculated within the report by dividing customers' returned merchandise value by their invoiced merchandise value.
  
```sql
--SQL VIEW--
CREATE VIEW [dbo].[VendorReturns_view]
AS 

SELECT
	im.Supplier,
	SUM(CASE WHEN asm.DocumentType = 'I' THEN asm.InvoiceQty ELSE 0 END) AS UnitsSold,
	SUM(CASE WHEN asm.DocumentType = 'I' THEN asm.InvoiceValue ELSE 0 END) AS GrossSales,
	SUM(CASE WHEN asm.DocumentType = 'C' THEN asm.InvoiceQty ELSE 0 END) AS UnitsReturn,
	SUM(CASE WHEN asm.DocumentType = 'C' THEN asm.InvoiceValue ELSE 0 END) AS TotalReturn,
	CONVERT(date, asm.TrnDate) AS Date
FROM
	Database.dbo.SalesTable asm
LEFT JOIN Database.dbo.InventoryTable im ON im.StockCode = asm.StockCode
GROUP BY
	im.Supplier,
	CONVERT(date, asm.TrnDate)

GO

--SQL Stored Procedure--
CREATE PROCEDURE [dbo].[VendorReturns] 
	@startdate Date,
	@enddate Date
AS
BEGIN
	SET NOCOUNT ON;

  SELECT
    *
  FROM
    [EOReportingDB].[dbo].[VendorReturns_view]
  WHERE
    VendorReturns_view.Date >= @startdate
    AND VendorReturns_view.Date <= @enddate
END
GO
