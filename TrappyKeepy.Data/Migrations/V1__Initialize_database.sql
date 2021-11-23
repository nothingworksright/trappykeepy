/*******************************************************************************
 * Migration:   TrappyKeepy
 * Version:     V1
 * Created:     2021-11-20
 * Author:      Joshua Gray
 * Description: Initialize the TrappyKeepy database, creating the schema, the 
 *              type for the users table, the users table, a function to query
 *              the users table, and a function to return table types.
 ******************************************************************************/

/**
 * Schema:      tk
 * Created:     2021-11-20
 * Author:      Joshua Gray
 * Description: The namespace for TrappyKeepy types, tables, and functions.
 */
CREATE SCHEMA IF NOT EXISTS tk;
COMMENT ON SCHEMA tk IS 'The namespace for TrappyKeepy types, tables, and functions.';

/**
 * Function:    tk.get_table_types
 * Created:     2021-11-20
 * Author:      Joshua Gray
 * Description: Function to return table column types.
 * Parameters:  table_name TEXT - The name of the table without the schema.
 * Usage:       SELECT * FROM tk.get_table_types('users');
 * Returns:     column_name, data_type
 */
CREATE OR REPLACE FUNCTION tk.get_table_types (table_name TEXT)
    RETURNS TABLE (column_name VARCHAR ( 255 ), data_type VARCHAR ( 255 ))
    LANGUAGE PLPGSQL
    AS
$$
BEGIN
    CREATE TEMP TABLE IF NOT EXISTS users_information_schema_columns(
        column_name VARCHAR ( 255 ),
        data_type VARCHAR ( 255 )
    ) ON COMMIT DROP;

    INSERT INTO users_information_schema_columns ( column_name, data_type )
    SELECT isc.column_name, isc.data_type
    FROM information_schema.columns as isc
    WHERE isc.table_name = $1;

    RETURN QUERY
    SELECT * FROM users_information_schema_columns;
END;
$$;
COMMENT ON FUNCTION tk.get_table_types IS 'Function to return table column types.';

/**
 * Type:        tk.user_type
 * Created:     2021-11-20
 * Author:      Joshua Gray
 * Description: Type for an individual user record including login credentials.
 * Attributes:  id UUID - Very low probability that a UUID will be duplicated.
 *              name VARCHAR(50) - 50 char limit for display purposes.
 *              password TEXT - Salted/hashed passwords using pgcrypto.
 *              email TEXT - 
 *              date_created TIMESTAMPTZ - 
 *              date_activated TIMESTAMPTZ - 
 *              date_last_login TIMESTAMPTZ - 
 */
CREATE TYPE tk.user_type AS (
    id UUID,
    name VARCHAR ( 50 ),
    password TEXT,
    email TEXT,
    date_created TIMESTAMPTZ,
    date_activated TIMESTAMPTZ,
    date_last_login TIMESTAMPTZ
);
COMMENT ON TYPE tk.user_type IS 'Type for a user record.';

/**
 * Table:       tk.users
 * Created:     2021-11-20
 * Author:      Joshua Gray
 * Description: Table to store user records.
 * Columns:     id - Primary key with default using the gen_random_uuid() function.
 *              name - Unique, and not null.
 *              password - Not null.
 *              email - Unique, and not null.
 *              date_created - Not null.
 *              date_activated - 
 *              date_last_login - 
 */
CREATE TABLE IF NOT EXISTS tk.users OF tk.user_type (
    id WITH OPTIONS PRIMARY KEY DEFAULT gen_random_uuid(),
    name WITH OPTIONS UNIQUE NOT NULL,
    password WITH OPTIONS NOT NULL,
    email WITH OPTIONS UNIQUE NOT NULL,
    date_created WITH OPTIONS NOT NULL
);
COMMENT ON TABLE tk.users IS 'User records including login credentials.';
COMMENT ON COLUMN tk.users.id IS 'UUID primary key.';
COMMENT ON COLUMN tk.users.name IS 'Unique display name.';
COMMENT ON COLUMN tk.users.password IS 'Salted/Hashed password using the pgcrypto crypt function, and gen_salt with the blowfish algorithm and iteration count of 8.';
COMMENT ON COLUMN tk.users.email IS 'Unique email address.';
COMMENT ON COLUMN tk.users.date_created IS 'Datetime the user was created in the database.';
COMMENT ON COLUMN tk.users.date_activated IS 'Datetime the user was activated for login.';
COMMENT ON COLUMN tk.users.date_last_login IS 'Datetime the user last logged into the system successfully.';

/**
 * Function:   tk.users_create
 * Created:     2021-11-21
 * Author:      Joshua Gray
 * Description: Function to create a record in the users table.
 * Parameters:  name VARCHAR(50) - Unique user display name.
 *              password TEXT - Plain text user password that will be salted/hashed.
 *              email TEXT - The user's 
 *              date_created TIMESTAMPTZ -
 * Usage:       SELECT * FROM tk.users_insert('foo', 'passwordfoo', 'foo@example.com', '2021-10-10 10:10:10-10');
 * Returns:     
 */
CREATE OR REPLACE FUNCTION tk.users_insert (
    name VARCHAR( 50 ),
    password TEXT,
    email TEXT,
    date_created TIMESTAMPTZ
)
    RETURNS TABLE (id UUID)
    LANGUAGE PLPGSQL
    AS
$$
DECLARE
    saltedhash TEXT;
BEGIN
    SELECT crypt($2, gen_salt('bf', 8)) INTO saltedhash;

    RETURN QUERY
    INSERT INTO tk.users (name, password, email, date_created)
    VALUES ($1, saltedhash, $3, $4)
    RETURNING tk.users.id;
END;
$$;
COMMENT ON FUNCTION tk.users_insert IS 'Function to create a record in the users table.';

/**
 * Function:    tk.users_read_all
 * Created:     2021-11-20
 * Author:      Joshua Gray
 * Description: Function to return all records from the users table.
 * Parameters:  None
 * Usage:       SELECT * FROM tk.users_read_all();
 * Returns:     All columns for all records from the tk.users table.
 */
CREATE OR REPLACE FUNCTION tk.users_read_all ()
    RETURNS SETOF tk.users
    LANGUAGE PLPGSQL
    AS
$$
BEGIN
    RETURN QUERY
    SELECT * FROM tk.users;
END;
$$;
COMMENT ON FUNCTION tk.users_read_all IS 'Function to return all records from the users table.';

/**
 * Function:    tk.users_read_by_id
 * Created:     2021-11-22
 * Author:      Joshua Gray
 * Description: Function to return a record from the users table by id.
 * Parameters:  id_value UUID - The id of the user record.
 * Usage:       SELECT * FROM tk.users_read_by_id('204208b8-04d8-4c56-a08a-cb4b4f2ec5ea');
 * Returns:     All columns for a record from the tk.users table.
 */
CREATE OR REPLACE FUNCTION tk.users_read_by_id (
    id_value UUID
)
    RETURNS SETOF tk.users
    LANGUAGE PLPGSQL
    AS
$$
BEGIN
    RETURN QUERY
    SELECT * FROM tk.users WHERE tk.users.id = $1;
END;
$$;
COMMENT ON FUNCTION tk.users_read_by_id IS 'Function to return a record from the users table by id.';

/**
 * Function:    tk.users_count_by_column_value_text
 * Created:     2021-11-22
 * Author:      Joshua Gray
 * Description: Function to return the count of user records that match a given column/value.
 * Parameters:  column_name TEXT - The name of the column to match on.
 *              column_value TEXT - The value of the column to match on.
 * Usage:       SELECT * FROM tk.users_count_by_column_value_text('name', 'foo');
 * Returns:     An integer count of the number of matching records found.
 */
CREATE OR REPLACE FUNCTION tk.users_count_by_column_value_text (
    column_name TEXT,
    column_value TEXT
)
    RETURNS integer
    LANGUAGE PLPGSQL
    AS
$$
DECLARE
    row_count integer;
    query text := 'SELECT COUNT(*) FROM tk.users';
BEGIN
    IF column_name IS NOT NULL THEN
        query := query || ' WHERE ' || quote_ident(column_name) || ' = $1';
    END IF;
    EXECUTE query USING column_value INTO row_count;
    RETURN row_count;
END;
$$;
COMMENT ON FUNCTION tk.users_count_by_column_value_text IS 'Function to count records from the users table by the specified column/value.';

/**
 * Function:    tk.users_update
 * Created:     2021-11-22
 * Author:      Joshua Gray
 * Description: Function to update a record in the users table. The Id cannot be changed. The password can only be changed via tk.users_update_password(). The date_created cannot be changed.
 * Parameters:  id UUID - Primary key id for the record to be updated.
 *              name VARCHAR(50)
 *              email TEXT
 *              date_activated TIMESTAMPTZ
 *              date_last_login TIMESTAMPTZ
 * Usage:       SELECT * FROM tk.users_update('a1e84bb3-3429-4bfc-95c8-e184fceaa036', 'foo', 'foo@example.com', '2021-10-10T13:10:10');
 * Returns:     True if the user was updated, and false if not.
 */
CREATE OR REPLACE FUNCTION tk.users_update (
    id UUID,
    name VARCHAR( 50 ) DEFAULT NULL,
    email TEXT DEFAULT NULL,
    date_activated TIMESTAMPTZ DEFAULT NULL,
    date_last_login TIMESTAMPTZ DEFAULT NULL,
)
    RETURNS BOOLEAN
    LANGUAGE PLPGSQL
    AS
$$
BEGIN
    UPDATE tk.users
    SET name = COALESCE($2, tk.users.name),
        email = COALESCE($3, tk.users.email),
        date_activated = COALESCE($4, tk.users.date_activated),
        date_last_login = COALESCE($5, tk.users.date_last_login)
    WHERE tk.users.id = $1;
    RETURN FOUND;
END;
$$;
COMMENT ON FUNCTION tk.users_update IS 'Function to update a record in the users table. ';

/**
 * Function:    tk.users_update_password
 * Created:     2021-11-22
 * Author:      Joshua Gray
 * Description: Function to update a record in the users table with a new password.
 * Parameters:  id UUID - Primary key id for the record to be updated.
 *              password TEXT - The new password to be salted/hashed and saved.
 * Usage:       SELECT * FROM tk.users_update_password('a1e84bb3-3429-4bfc-95c8-e184fceaa036', 'passwordfoo');
 * Returns:     True if the user password was updated, and false if not.
 */
CREATE OR REPLACE FUNCTION tk.users.update_password (
    id UUID,
    password TEXT
)
    RETURNS BOOLEAN
    LANGUAGE PLPGSQL
    AS
$$
DECLARE
    saltedhash TEXT;
BEGIN
    SELECT crypt($2, gen_salt('bf', 8)) INTO saltedhash;

    UPDATE tk.users
    SET password = saltedhash
    WHERE tk.users.id = $1
    RETURN FOUND;
END;
$$;
COMMENT ON FUNCTION tk.users.update_password IS 'Function to update a record in the users table with a new password.';

/**
 * Function:    tk.users_delete_by_id
 * Created:     2021-11-23
 * Author:      Joshua Gray
 * Description: Function to delete a record from the users table by id.
 * Parameters:  id UUID - Primary key id for the record to be deleted.
 * Usage:       SELECT * FROM tk.users_delete_by_id('a1e84bb3-3429-4bfc-95c8-e184fceaa036');
 * Returns:     True if the user was deleted, and false if not.
 */
CREATE OR REPLACE FUNCTION tk.users_delete_by_id (
    id_value UUID
)
    RETURNS BOOLEAN
    LANGUAGE PLPGSQL
    AS
$$
BEGIN
    DELETE FROM tk.users
    WHERE tk.users.id = $1;
    RETURN FOUND;
END;
$$;
COMMENT ON FUNCTION tk.users_delete_by_id IS 'Function to delete a record from the users table by id.';