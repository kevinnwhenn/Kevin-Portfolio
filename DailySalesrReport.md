![image](https://github.com/kevinnwhenn/Kevin-Portfolio/assets/109677078/c56eb244-78b4-4541-b16e-9576b07fa372)
![image](https://github.com/kevinnwhenn/Kevin-Portfolio/assets/109677078/ba40a974-c937-451a-8c7c-43689a896dc3)
![image](https://github.com/kevinnwhenn/Kevin-Portfolio/assets/109677078/de00885f-dc6f-48fa-8365-e933294590d8)


```sql

CREATE VIEW [dbo].[EO_DailySalesReport_view]
AS 

SELECT
	SorMaster.ShippingInstrsCod as Route,
	CONVERT(date, ArSalesMove.TrnDate) AS Date,
	SUM(ArSalesMove.InvoiceValue) AS NetSales,
	SUM(CASE WHEN ArSalesMove.DocumentType = 'I' THEN ArSalesMove.InvoiceValue ELSE 0 END) as GrossSales,
	SUM(ArSalesMove.CostValue) AS Cost,
	SUM(CASE WHEN ArSalesMove.DocumentType = 'C' THEN ArSalesMove.InvoiceValue ELSE 0 END) as Returns
FROM
	Syspro1.dbo.ArSalesMove
LEFT JOIN Syspro1.dbo.SorMaster on SorMaster.SalesOrder = ArSalesMove.SalesOrder
WHERE
	YEAR(ArSalesMove.TrnDate) IN (2022, 2023)
GROUP BY
	ArSalesMove.TrnDate,
	SorMaster.ShippingInstrsCod

GO


```
