-- Temporary table that contains the customer age:

create temporary table bank.den_age as
select cust.customer_id,
year(current_date())-year(cust.birth_date) -
case 
	when month(current_date()) > month(cust.birth_date) or
    (month(current_date()) = month(cust.birth_date) 
    and day(current_date()) >= day(cust.birth_date)) then 0 
    else 1
end as age
from bank.customer cust;

/*
Temporary table that contains:
 - the total number of accounts; 
 - the number of accounts by type:
*/

create temporary table bank.den_accounts as
select
cust.customer_id as id_1,
count(distinct acc.account_id) as number_accounts,
count(distinct 
	case 
		when tacc.account_type_description = 'Basic account' then acc.account_id
        else null
	end) as number_accounts_basic,
count(distinct 
	case 
		when tacc.account_type_description = 'Business account' then acc.account_id
        else null
	end) as number_accounts_business,
count(distinct 
	case 
		when tacc.account_type_description = 'Private account' then acc.account_id
        else null
	end) as number_accounts_private,
count(distinct 
	case 
		when tacc.account_type_description = 'Family account' then acc.account_id
        else null
	end) as number_accounts_family
from bank.customer cust
left join bank.account acc
on cust.customer_id = acc.customer_id
left join bank.account_type tacc
on acc.account_type_id = tacc.account_type_id
group by 1;

/*
Temporary table that contains:
 - the total number of incoming and outgoing transactions;
 - the number of incoming and outgoing transactions by type;
 - the total expenditure;
 - the total income:
*/

create temporary table bank.den_tra_type as
select 
cust.customer_id as id_2,
sum(case when ttra.sign = '-' then 1 else 0 end) as outgoing_transactions,
sum(case when ttra.sign = '+' then 1 else 0 end) as incoming_transactions,
sum(case 
		when ttra.transaction_type_description = 'Purchase on Amazon' then 1
        else 0
	end) as outgoing_transactions_amazon,
sum(case 
		when ttra.transaction_type_description = 'Mortgage payment' then 1
        else 0
	end) as outgoing_transactions_mortgage,
sum(case 
		when ttra.transaction_type_description = 'Hotel' then 1
        else 0
	end) as outgoing_transactions_hotel,
sum(case 
		when ttra.transaction_type_description = 'Plane ticket' then 1
        else 0
	end) as outgoing_transactions_plane,
sum(case 
		when ttra.transaction_type_description = 'Supermarket' then 1
        else 0
	end) as outgoing_transactions_supermarket,
sum(case 
		when ttra.transaction_type_description = 'Salary' then 1
        else 0
	end) as incoming_transactions_salary,
sum(case 
		when ttra.transaction_type_description = 'Pension' then 1
        else 0
	end) as incoming_transactions_pension,
sum(case 
		when ttra.transaction_type_description = 'Dividends' then 1
        else 0
	end) as incoming_transactions_dividends,
round(sum(case when ttra.sign = '-' then tra.amount else 0 end), 2) as expenditure_total_amount,
round(sum(case when ttra.sign = '+' then tra.amount else 0 end), 2) as income_total_amount
from bank.customer cust
left join bank.account acc
on cust.customer_id = acc.customer_id
left join bank.transaction tra
on acc.account_id = tra.account_id
left join bank.transaction_type ttra
on tra.transaction_type_id = ttra.transaction_type_id
group by 1
order by 1;

/*
Temporary table that contains:
 - the total expenditure by account tipe;
 - the total income by account type:
*/

create temporary table bank.den_acc_type as
select cust.customer_id as id_3,
round(sum(case 
		when ttra.sign = '-' and tacc.account_type_description = 'Basic account' then tra.amount 
        else 0 
	end), 2) as expenditure_total_amount_basic,
round(sum(case 
		when ttra.sign = '+' and tacc.account_type_description = 'Basic account' then tra.amount 
        else 0 
	end), 2) as income_total_amount_basic,
round(sum(case 
		when ttra.sign = '-' and tacc.account_type_description = 'Business account' then tra.amount 
        else 0 
	end), 2) as expenditure_total_amount_business,
round(sum(case 
		when ttra.sign = '+' and tacc.account_type_description = 'Business account' then tra.amount 
        else 0 
	end), 2) as income_total_amount_business,
round(sum(case 
		when ttra.sign = '-' and tacc.account_type_description = 'Private account' then tra.amount 
        else 0 
	end), 2) as expenditure_total_amount_private,
round(sum(case 
		when ttra.sign = '+' and tacc.account_type_description = 'Private account' then tra.amount 
        else 0 
	end), 2) as income_total_amount_private,
round(sum(case 
		when ttra.sign = '-' and tacc.account_type_description = 'Family account' then tra.amount 
        else 0 
	end), 2) as expenditure_total_amount_family,
round(sum(case 
		when ttra.sign = '+' and tacc.account_type_description = 'Family account' then tra.amount 
        else 0 
	end), 2) as income_total_amount_family
from bank.customer cust
left join bank.account acc
on cust.customer_id = acc.customer_id
left join bank.account_type tacc
on acc.account_type_id = tacc.account_type_id
left join bank.transaction tra
on acc.account_id = tra.account_id
left join bank.transaction_type ttra
on tra.transaction_type_id = ttra.transaction_type_id
group by 1
order by 1;



-- Final table:

create table bank.denormalized as
select *
from bank.den_age dage
left join bank.den_accounts dacc
on dage.customer_id = dacc.id_1
left join bank.den_tra_type dttra
on dage.customer_id = dttra.id_2
left join bank.den_acc_type dtacc
on dage.customer_id = dtacc.id_3;

alter table bank.denormalized 
drop column id_1,
drop column id_2,
drop column id_3; 

/*
To export the view to a CSV file, let us first see where the file will be saved by 
executing the following command:
*/

show variables like "secure_file_priv";

/*
At this point, we can copy and paste this location and add the file name to it:

	"secure_file_priv_location\file_name.csv"

If we wanted to change the export location specified in the "secure_file_priv"
variable, we should change it by modifying the "my.ini" configuration file, which
is usually located on this path:

		C:\ProgramData\MySQL\MySQL Server X.Y

In particular, we simply need to find the "secure_file_priv" variable and set a 
new location to export MySQL data. For further information, check out the following
webpage:

		https://solutioncenter.apexsql.com/how-to-export-mysql-data-to-csv/

Since I want to create a CSV file with the field names in the first row, and 
manually writing all of them is tedious, I use the result of the following query:
*/

select group_concat(concat("'",column_name,"'") 
					order by ordinal_position) as column_names
from information_schema.columns
where table_name = 'denormalized'
and table_schema = 'bank';

/*
We perform a 'Copy Row (unquoted)' of the result and paste it in the final
query to export the view to a CSV file called "denormalized_table.csv":
*/

select 'customer_id','age','number_accounts','number_accounts_basic','number_accounts_business',
'number_accounts_private','number_accounts_family','outgoing_transactions','incoming_transactions',
'outgoing_transactions_amazon','outgoing_transactions_mortgage','outgoing_transactions_hotel',
'outgoing_transactions_plane','outgoing_transactions_supermarket','incoming_transactions_salary',
'incoming_transactions_pension','incoming_transactions_dividends','expenditure_total_amount',
'income_total_amount','expenditure_total_amount_basic','income_total_amount_basic',
'expenditure_total_amount_business','income_total_amount_business','expenditure_total_amount_private',
'income_total_amount_private','expenditure_total_amount_family','income_total_amount_family'

union

select * from bank.denormalized
into outfile 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\denormalized_table.csv'
fields terminated by ','
optionally enclosed by '"'
lines terminated by '\n';

/*
The OPTIONALLY ENCLOSED BY clause is influenced by the presence of the row with
the column names and this results in all the values being enclosed by '"'. For 
this reason, a useful workaround is to produce the CSV file without the field names
(i.e. without using the UNION operator) and then manually append 
the column headers to it by copying the result of the previous query.
*/