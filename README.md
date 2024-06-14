# open-aggregates

Open Aggregates provides SQL statements for creating user-defined aggregate functions (UDAFs) that calculate statistical moments that supplement the native aggregate functionality of databases like SingleStore. These UDAFs allow the user to calculate summary statistics like skewness and kurtosis. 

## Prerequisites

A SingleStore database instance is required to create and utilize the UDAFs.

## Installation

1. Connect to the database using your desired connection options such as user name and database.
    * One way to connect to the database is with the [SingleStore client](https://docs.singlestore.com/db/v8.5/user-and-cluster-administration/cluster-management-with-tools/singlestore-client/).
1. Create or identify a database where the UDAFs will be created.
1. If necessary, issue a `USE` statement to switch to the database where the UDAFs will be created.
    ``` sql
    use aggregate_database;
    ```
1. Make sure the user creating the UDAFs has sufficient database privileges.
    * Other users will also need properly-configured database privileges in order to invoke the UDAFs.
    * See SingleStore documentation on the [GRANT statement](https://docs.singlestore.com/db/v8.5/reference/sql-reference/security-management-commands/grant/) and [Role-Based Access Control](https://docs.singlestore.com/db/v8.5/security/administration/role-based-access-control-rbac-at-database-level/).
    * Also consult the [Database Privileges](#database-privileges) section below.
1. Execute the SQL statements in [src/udafs.sql](src/udafs.sql). There are many ways to execute these statements and you can choose whichever method works best for you. Here are two options:
    * Issue a `SOURCE` statement from the database client application to execute a local copy of [src/udafs.sql](src/udafs.sql).
        ``` sql
        source udafs.sql;
        ```
    * Copy and paste statements from [src/udafs.sql](src/udafs.sql) into the client application. You may be able to copy and paste all of the statements at once.
1. Ensure that output from the validation statements at the bottom of [src/udafs.sql](src/udafs.sql) looks correct.
    * The validation statements are:
        ``` sql
        show aggregates;
        select sas_m_three_udaf(1), sas_m_three_m_four_udaf(1) from dual;
        ```
    * Output from the validation statements should look like this:
        ``` sql
        singlestore> show aggregates;
        +-----------------------------------+
        | Aggregates_in_aggregate_database  |
        +-----------------------------------+
        | sas_m_three_m_four_udaf           |
        | sas_m_three_udaf                  |
        +-----------------------------------+
        2 rows in set (0.00 sec)

        singlestore> select sas_m_three_udaf(1), sas_m_three_m_four_udaf(1) from dual;
        +---------------------+----------------------------+
        | sas_m_three_udaf(1) | sas_m_three_m_four_udaf(1) |
        +---------------------+----------------------------+
        |                   0 | {"m3":0,"m4":0}            |
        +---------------------+----------------------------+
        1 row in set (0.00 sec)
        ```

## UDAFs

Two UDAFs are installed by [src/udafs.sql](src/udafs.sql):
* `sas_m_three_udaf`
* `sas_m_three_m_four_udaf`

### SAS_M_THREE_UDAF

Returns the third statistical moment.

#### Syntax
``` sql
sas_m_three_udaf ( <expression> )
```

#### Arguments
* expression: any numeric expression

#### Return type
The return type is `double`.

#### Examples
``` sql
singlestore> select sas_m_three_udaf(msrp) from cars;
+------------------------+
| sas_m_three_udaf(msrp) |
+------------------------+
|   8.725500198069908e15 |
+------------------------+
1 row in set (0.08 sec)
```

### SAS_M_THREE_M_FOUR_UDAF

Returns the third and fourth statistical moments.

#### Syntax
``` sql
sas_m_three_m_four_udaf ( <expression> )
```

#### Arguments
* expression: any numeric expression

#### Return type
The return type is a JSON object:
* The JSON object contains two key/value pairs
* The keys are named `m3` and `m4`
* Each key has a value whose data type is `double`
* The value of `m3` is the third statistical moment
* The value of `m4` is the fourth statistical moment

#### Examples
``` sql
singlestore> select sas_m_three_m_four_udaf(msrp) from cars;
+-------------------------------------------------------+
| sas_m_three_m_four_udaf(msrp)                         |
+-------------------------------------------------------+
| {"m3":8.72550019806991e15,"m4":1.0145348454666838e21} |
+-------------------------------------------------------+
1 row in set (0.15 sec)

singlestore> select JSON_EXTRACT_DOUBLE(m3m4, 'm3') as m3, JSON_EXTRACT_DOUBLE(m3m4, 'm4') as m4
    -> from (select sas_m_three_m_four_udaf(msrp) as m3m4 from cars);
+----------------------+-----------------------+
| m3                   | m4                    |
+----------------------+-----------------------+
| 8.725500198069909e15 | 1.0145348454666839e21 |
+----------------------+-----------------------+
1 row in set (0.00 sec)
```

For more information on JSON_EXTRACT_DOUBLE and other JSON functions, see SingleStore documentation on [JSON functions](https://docs.singlestore.com/db/v8.5/reference/sql-reference/json-functions/).

## Database Privileges
Any user/invoker of the UDAFs must be granted the `EXECUTE` privilege. Below are two ways to achieve this:

### Via Groups
Database groups can be a helpful way to organize users who all share a role, and grant the `EXECUTE` privilege on the UDAFs to the role. Here is one way to do so:

1. Create a group, something like `aggregate_group`.
    ``` sql
    create group 'aggregate_group';
    ```

1. Create a role, something like `aggregate_role`.
    ``` sql
    create role 'aggregate_role';
    ```

1. Grant the `EXECUTE` privilege to the role so that users in the role can invoke the UDAFs in a database named, for example, `aggregate_database`.
    ``` sql
    grant execute on aggregate_database.* to role 'aggregate_role';
    ```

1. Assign the role to the group you created.
    ``` sql
    grant role 'aggregate_role' to 'aggregate_group';
    ```

1. Now, any user can be added to `aggregate_group` and they will inherit the `EXECUTE` privilege on the UDAFs in `aggregate_database`. For example, we can add a user named `aggregate_user` to the group:
    ``` sql
    grant group 'aggregate_group' to 'aggregate_user';
    ```

### Via Users
Alternatively, users can be directly granted the `EXECUTE` privilege on the UDAFs.
``` sql
grant execute on aggregate_database.* to 'test_user';
```

## Troubleshooting

One potential issue is improperly-configured database privileges. This could lead to an inability of certain database users to invoke the UDAFs. Please consult SingleStore documentation on the [GRANT statement](https://docs.singlestore.com/db/v8.5/reference/sql-reference/security-management-commands/grant/) and [Role-Based Access Control](https://docs.singlestore.com/db/v8.5/security/administration/role-based-access-control-rbac-at-database-level/) if you run into issues in this area.

## Contributing

> We welcome your contributions! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to submit contributions to this project.

## License

> This project is licensed under the [Apache 2.0 License](LICENSE).

## Additional Resources

* [SingleStore User-Defined Aggregate Functions](https://docs.singlestore.com/db/v8.5/reference/sql-reference/procedural-sql-reference/create-aggregate/)
* [SingleStore Client](https://docs.singlestore.com/db/v8.5/user-and-cluster-administration/cluster-management-with-tools/singlestore-client/)
* [SingleStore Role-Based Access Control](https://docs.singlestore.com/db/v8.5/security/administration/role-based-access-control-rbac-at-database-level/)
* [SingleStore GRANT Statement](https://docs.singlestore.com/db/v8.5/reference/sql-reference/security-management-commands/grant/)
* [SingleStore JSON Functions](https://docs.singlestore.com/db/v8.5/reference/sql-reference/json-functions/)
* [SAS SingleStore Data Connector](https://documentation.sas.com/?cdcId=pgmsascdc&cdcVersion=default&docsetId=casref&docsetTarget=n17k3u020i60txn1mrtroklspwl8.htm)