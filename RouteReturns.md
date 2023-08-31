### Display Route Return Rates
- **Question**: Which of our routes are returning the most amount of product?
- Return rate is calculated within the report by dividing customers' returned merchandise value by their invoiced merchandise value.
- Stored procedure is created with date. This will allow the user to view data based on their desired date range.

```sql
--SQL VIEW--
CREATE VIEW [dbo].[RouteReturns_view]
AS
SELECT
    SalesTable.TrnYear,
    SalesTable.TrnMonth,
    SalesMaster.ShippingInstrs,
    SUM(CASE WHEN SalesTable.DocumentType = 'I' THEN SalesTable.InvoiceValue ELSE 0 END) AS Invoices,
    SUM(CASE WHEN SalesTable.DocumentType = 'C' THEN SalesTable.InvoiceValue ELSE 0 END) AS Credits,
    CONVERT(date, SalesTable.TrnDate) as Date
FROM
    Database.dbo.ArSalesMove
LEFT JOIN Database.dbo.SorMaster ON SalesMaster.SalesOrder = SalesTable.SalesOrder
GROUP BY
    SalesTable.TrnYear,
    SalesTable.TrnMonth,
    SalesMaster.ShippingInstrs,
    SalesTable.TrnDate
GO

--SQL Stored Procedure--
CREATE PROCEDURE [dbo].[RouteReturns] 
    @startdate Date,
	  @enddate Date
AS
BEGIN
    SET NOCOUNT ON;
Select
  *
From
    [dbo].[RouteReturns_view]
Where
    RouteReturns.Date >= @startdate
    AND RouteReturns.Date <= @enddate
END
GO
