--Inspecting Data
select *
from sales_data_sample

--Checking unique values
select distinct status from [dbo].[sales_data_sample] --nice to plot 
select distinct year_id from [dbo].[sales_data_sample]
select distinct PRODUCTLINE from [dbo].[sales_data_sample]-- nice to plot
select distinct COUNTRY from [dbo].[sales_data_sample]--nice to plot 
select distinct DEALSIZE from [dbo].[sales_data_sample] --nice to plot
select distinct TERRITORY from [dbo].[sales_data_sample]-- nice to plot

Select distinct Month_Id from sales_data_sample
where YEAR_ID = 2003

--Ananlysis
--starting grouping sales by productive 
select PRODUCTLINE, sum(sales) Revenue
from sales_data_sample
Group By PRODUCTLINE
Order by 2 desc

Select Year_ID, SUM(sales) Revenue
from sales_data_sample
group by YEAR_ID
Order by 2 desc

Select DEALSIZE, SUM(sales) Revenue
from project.dbo.sales_data_sample
group by DEALSIZE
order by 2 Desc

--What was the best month for sales in specifc year? How much earning in that month?
Select Month_ID, SUM(sales) Revenue, COUNT(ORDERNUMBER) Frequency
from project.dbo.sales_data_sample
where YEAR_ID = 2004 --Changing year to see the rest part
group by MONTH_ID
order by 2 Desc

--November seems to be the month, What product do they sell in November, Classic I believe
Select Month_id, PRODUCTLINE, sum(sales) Revenue, COUNT(ORDERNUMBER)
From project.dbo.sales_data_sample
Where YEAR_ID = 2004 and MONTH_ID = 11 -- By changing the year we can see the rest part
group by MONTH_ID, PRODUCTLINE
order by 3 desc

--Who is your best customer (this could be best answered with Recency-Frequency Monetary(RFM)
DROP TABLE IF EXISTS #rfm
;with rfm as 
(
	select 
		CUSTOMERNAME, 
		sum(sales) MonetaryValue,
		avg(sales) AvgMonetaryValue,
		count(ORDERNUMBER) Frequency,
		max(ORDERDATE) last_order_date,
		(select max(ORDERDATE) from [dbo].[sales_data_sample]) max_order_date,
		DATEDIFF(DD, max(ORDERDATE), (select max(ORDERDATE) from [dbo].[sales_data_sample])) Recency
	from [project].[dbo].[sales_data_sample]
	group by CUSTOMERNAME
),
rfm_calc as
(

	select r.*,
		NTILE(4) OVER (order by Recency desc) rfm_recency,
		NTILE(4) OVER (order by Frequency) rfm_frequency,
		NTILE(4) OVER (order by MonetaryValue) rfm_monetary
	from rfm r
	
)
Select c.*, rfm_recency + rfm_frequency + rfm_monetary as rfm_cell,
cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary as varchar)rfm_cell_string
into #rfm
from rfm_calc c

select CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_monetary,
	case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_cell_string in (311, 411, 331) then 'new customers'
		when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_string in (323, 333,321, 422, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment

from #rfm

--What products are most often sold together?
-- Select * from sales_data_sample where orderNumber = 10411
Select distinct Ordernumber, STUFF(
(Select ','+ PRODUCTCODE
from sales_data_sample p
where ORDERNUMBER in
(

Select ORDERNUMBER
from(
Select ORDERNUMBER, count(*) rn
from sales_data_sample
where STATUS = 'Shipped'
group by ORDERNUMBER
)m
where rn = 3
)
and p.ORDERNUMBER = s.ORDERNUMBER
    for xml path (''))
	, 1 , 1 ,'') ProductCodes

	from sales_data_sample s
	Order by 2 desc




