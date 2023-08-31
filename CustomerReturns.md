### Display Customer Return Rates
- **Question**: Which of our customers are returning the most amount of product?
- Return rate is calculated within the report by dividing customers' returned merchandise value by their invoiced merchandise value.
- Stored procedure is created with date and salesperson parameters. This will allow the user to view data based on their desired date range and salesperson. If salesperson parameter ```IS NULL``` then report will populate values summed together.

```sql
SELECT
	ArSalesMove.TrnYear,
	ArSalesMove.TrnMonth,
	ArSalesMove.Customer,
	ArCustomer.Name,
	SUM(CASE WHEN ArSalesMove.DocumentType = 'I' THEN ArSalesMove.InvoiceValue ELSE 0 END) AS Invoices,
	SUM(CASE WHEN ArSalesMove.DocumentType = 'C' THEN ArSalesMove.InvoiceValue ELSE 0 END) AS Credits,
	CONVERT(date, ArSalesMove.TrnDate) AS Date,
	ArSalesMove.Salesperson
FROM
	Syspro1.dbo.ArSalesMove
LEFT JOIN Syspro1.dbo.ArCustomer ON ArCustomer.Customer = ArSalesMove.Customer
GROUP BY
	ArSalesMove.TrnYear,
	ArSalesMove.TrnMonth,
	ArSalesMove.Customer,
	ArCustomer.Name,
	CONVERT(date, ArSalesMove.TrnDate),
	ArSalesMove.Salesperson
```
