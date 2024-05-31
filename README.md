# open-aggregates

Open Aggregates provides SQL statements for creating user-defined aggregate functions that calculate statistical moments that supplement the native aggregate functionality of databases like Singlestore. These aggregates allow the user to calculate summary statistics like skewness and kurtosis. 

## Prerequisites

A Singlestore database instance is required to create and utilitze the aggregate functions.

## Installation

1. Connect to the database. One option to connect to the database is the [Singlestore client](https://docs.singlestore.com/cloud/connect-to-your-workspace/connect-with-the-singlestore-client/).
1. Create a database where the aggregates will be created if you don't already have such a database. 
1. Make sure the user creating the aggregates has sufficient permissions. Note that other users will also need properly-configured grants in order to execute the aggregates. See this [documentation about grants](https://docs.singlestore.com/cloud/reference/sql-reference/security-management-commands/grant/). Also consult the [Permissions Section](#permissions) below
1. Copy and paste all of the statements from [src/m_three_m_four_udaf.sql](src/m_three_m_four_udaf.sql) into the Singlestore client. You can copy and paste all of the statements at once. Alternatively, you can run the Singlestore client and redirect [src/m_three_m_four_udaf.sql](src/m_three_m_four_udaf.sql) into the Singlestore CLI tool with your desired database, username etc. Note that there are many ways to execute these statements. Choose whichever works best for your use case.
1. Ensure the output from the validation statements and the bottom of src/udafs.sql look correct. Those statements are:
	``` sql
	show aggregates;
	``` 
	``` sql
	select sas_m_three_udaf(1), sas_m_three_m_four_udaf(1) from dual;
	```
	

## Permissions
Any user/invoker of the user-defined aggregates must have execute permissions granted for the aggregate functions. Below are a couple different ways to achieve this:

### Via Groups
Database groups can be a helpful way to organize users who all share a role with execute permissions on user-defined aggregates. Here is one way to do so:
 
1. Create a group, something like 'aggregate_group'.
	``` sql
	create group 'aggregate_group';
	```
 
1. Create a role, something like 'aggregate_role'.
	``` sql
	create role 'aggregate_role';
	```
 
1. Grant execute permissions to the role so it can execute the user-defined aggregates in a database named, for example, aggregate_database.
	``` sql
	grant execute on aggregate_database.* to role aggregate_role;
	```
 
1. Assign the role with execute permissions to the group we created.
	``` sql
	grant role 'aggregate_role' to 'aggregate_group';
	```
 
1. Now, any user can be added to the aggregate_group and they will inherit execute privileges on aggregate_database. For example, we can add aggregate_user:
	``` sql
	grant group 'aggregate_group' to 'aggregate_user';
	```
 
### Via Users
Alternatively, users can be directly granted execute permissions for the user-defined aggregates. 
``` sql
grant execute on aggregate_database.* to test_user;
```
## Return Types 

The sas_m_three_m_four_udaf aggregate returns JSON structured like 
``` JSON 
{m3: double, m4: double}
``` 
where m3 is the third statistical moment and m4 is the fourth statistical moment. Singlestore has helpful documentation about parsing JSON [here](https://docs.singlestore.com/cloud/reference/sql-reference/json-functions/json-extract-type/). 

## Examples
Aggregates can be executed with their fully qualified name or their partially qualified name. 

For example, say you created the aggregates in a database called "aggregates_database". To calculate the third and fourth moments of a column of doubles named `msrp` in a  table named cars you could run a query like:
``` sql 
select aggregates_database.sas_m_three_m_four_udaf(msrp) from cars;
``` 
The query will return the values for the third and fourth moment in JSON form. 

## Troubleshooting

One potential issue is improperly-configured grants. This could lead to an inability of certain database users to execute the aggregates. Please consult [Singlestore's documentation](https://docs.singlestore.com/cloud/reference/sql-reference/security-management-commands/grant/) about grants if you run into issues in this area. 

## Contributing

> We welcome your contributions! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to submit contributions to this project. 

## License

> This project is licensed under the [Apache 2.0 License](LICENSE).

## Additional Resources

* [Singlestore User-Defined Aggregate Documentation](https://docs.singlestore.com/db/v8.5/reference/sql-reference/procedural-sql-reference/create-aggregate/#create-udaf)
* [SAS Singlestore Data Connector](https://go.documentation.sas.com/doc/en/pgmsascdc/v_044/casref/n17k3u020i60txn1mrtroklspwl8.htm)
* [Singlestore Client](https://docs.singlestore.com/cloud/connect-to-your-workspace/connect-with-the-singlestore-client/)
* [Singlestore Grants](https://docs.singlestore.com/cloud/reference/sql-reference/security-management-commands/grant/)