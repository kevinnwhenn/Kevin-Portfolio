### Display Customer Return Rates
- **Question**: Which of our customers are returning the most amount of product?
- Return rate is calculated within the report by dividing customers' returned merchandise value by their invoiced merchandise value.
- Stored procedure is created with date and salesperson parameters. This will allow the user to view data based on their desired date range and salesperson. If salesperson parameter ```IS NULL``` then report will populate values summed together.

```sql
--SQL VIEW--
SELECT
	SalesTable.TrnYear,
	SalesTable.TrnMonth,
	SalesTable.Customer,
	CustomerTable.Name,
	SUM(CASE WHEN SalesTable.DocumentType = 'I' THEN SalesTable.InvoiceValue ELSE 0 END) AS Invoices,
	SUM(CASE WHEN SalesTable.DocumentType = 'C' THEN SalesTable.InvoiceValue ELSE 0 END) AS Credits,
	CONVERT(date, SalesTable.TrnDate) AS Date,
	SalesTable.Salesperson
FROM
	Database.dbo.SalesTable
LEFT JOIN Database.dbo.CustomerTable ON CustomerTable.Customer = SalesTable.Customer
GROUP BY
	SalesTable.TrnYear,
	SalesTable.TrnMonth,
	SalesTable.Customer,
	CustomerTable.Name,
	CONVERT(date, SalesTable.TrnDate),
	SalesTable.Salesperson

--SQL Stored Procedure--
CREATE PROCEDURE [dbo].[CustomerReturns]
    	@startdate Date,
	@enddate Date,
	@salesid VarChar(10)
AS
BEGIN
    SET NOCOUNT ON;
Select
	*
From
    [dbo].[CustomerReturns_view]
Where
    CustomerReturns_view.Date BETWEEN @startdate AND @enddate
    AND (
        (ISNULL(@salesid, '') <> '' AND CustomerReturns_view.Salesperson = @salesid) OR
        (ISNULL(@salesid, '') = '')
    );
END
```
