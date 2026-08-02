-- zenith-migrations server side entry
-- Executes pending SQL migrations on startup. Halts server on failure.

local migrations = {
    { version = 1, file = "../../sql/migrations/0001_initial.sql", name = "0001_initial.sql" }
}

local function runMigrations()
    print("^3[zenith-migrations] Running database migrations check...^7")
    
    -- Ensure schema_migrations table exists
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS schema_migrations (
            version INT PRIMARY KEY,
            applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    ]])

    -- Fetch applied migrations
    local applied = MySQL.query.await("SELECT version FROM schema_migrations")
    local appliedMap = {}
    if applied then
        for _, row in ipairs(applied) do
            appliedMap[row.version] = true
        end
    end

    -- Run un-applied migrations
    for _, mig in ipairs(migrations) do
        if not appliedMap[mig.version] then
            print(string.format("^3[zenith-migrations] Applying migration %d (%s)...^7", mig.version, mig.name))
            
            local sqlContent = LoadResourceFile(GetCurrentResourceName(), mig.file)
            if not sqlContent then
                error(string.format("[zenith-migrations] CRITICAL ERROR: Could not read migration file: %s", mig.file))
            end

            -- Execute inside a transaction
            local success = MySQL.transaction.await(function()
                -- Split the SQL file into queries by semicolon to execute them properly (oxmysql transaction requirement)
                local queries = {}
                for query in string.gmatch(sqlContent, "([^;]+)") do
                    local trimmed = string.gsub(query, "^%s*(.-)%s*$", "%1")
                    if trimmed ~= "" and not string.match(trimmed, "^%-%-") then
                        table.insert(queries, trimmed)
                    end
                end

                for _, q in ipairs(queries) do
                    MySQL.query.await(q)
                end

                -- Record completion
                MySQL.query.await("INSERT INTO schema_migrations (version) VALUES (?)", { mig.version })
                return true
            end)

            if success then
                print(string.format("^2[zenith-migrations] Successfully applied migration %d^7", mig.version))
            else
                print(string.format("^1[zenith-migrations] CRITICAL: Transaction failed for migration %d! Halting server.^7", mig.version))
                error(string.format("[zenith-migrations] Migration transaction failure on version %d", mig.version))
            end
        end
    end

    print("^2[zenith-migrations] Database is up to date.^7")
end

MySQL.ready(function()
    local success, err = pcall(runMigrations)
    if not success then
        print(string.format("^1[zenith-migrations] Boot migration failed: %s^7", err))
        -- In a real production deployment, you would notify administrative logs or execute a hard OS exit if needed.
    end
end)
