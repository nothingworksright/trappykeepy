.PHONY: all
all: clean restore migrate build run

.PHONY: flyway
flyway:
	@# This will download and extract the Flyway application.
	# ----------
	# Downloading and extracting Flyway - https://flywaydb.org/
	wget -qO- https://repo1.maven.org/maven2/org/flywaydb/flyway-commandline/8.0.4/flyway-commandline-8.0.4-linux-x64.tar.gz | tar xvz

.PHONY: clean
clean:
	dotnet clean TrappyKeepy.Api

.PHONY: restore
restore:
	dotnet restore TrappyKeepy.Api
	dotnet clean TrappyKeepy.Data
	dotnet clean TrappyKeepy.Domain
	dotnet clean TrappyKeepy.Service
	dotnet clean TrappyKeepy.Test

.PHONY: migrate
migrate:
ifeq ($(origin ASPNETCORE_ENVIRONMENT), 'Production')
	# ----------
	# Environment is production
	# Environment variables need to be setup properly in production for this to work
	# Migrating the database
	./flyway-8.0.4/flyway -configFiles=flyway.conf migrate
else
	# ----------
	# Environment is development 
	# Environment variables are hard coded into the development migration command.
	# Migrating the database
	DB_URL="jdbc:postgresql://localhost:15432/keepydb" DB_USER="dbuser" DB_PASSWORD="dbpass" MIGRATIONS="filesystem:./TrappyKeepy.Data/Migrations" ./flyway-8.0.4/flyway -configFiles=flyway.conf migrate
endif

.PHONY: dbscaffold
dbscaffold:
	@# This will create or overwrite the database context class and model classes
	@# based on the current database structure.
	# ----------
	# Scaffolding the database context and model classes
	dotnet ef dbcontext scaffold Name=ConnectionStrings:keepydb --project TrappyKeepy.Api --context-namespace TrappyKeepy.Data --namespace TrappyKeepy.Domain --data-annotations --schema tk --context KeepyDbContext --context-dir ../TrappyKeepy.Data/DbContexts --output-dir ../TrappyKeepy.Domain/Models --force Npgsql.EntityFrameworkCore.PostgreSQL

.PHONY: format
format:
	@# This will format the code to match the .editorconfig file settings.
	# ----------
	# Applying code formatting
	dotnet format TrappyKeepy.Api
	dotnet format TrappyKeepy.Data
	dotnet format TrappyKeepy.Domain
	dotnet format TrappyKeepy.Service
	dotnet format TrappyKeepy.Test

.PHONY: build
build:
	@# This will build the TrappyKeepy.Api project.
	# ----------
	# Building the TrappyKeepy.Api project
	dotnet build TrappyKeepy.Api

.PHONY: test
test:
	dotnet test TrappyKeepy.Test

.PHONY: run
run:
	@# This will run the TrappyKeepy.Api project.
	# Running the TrappyKeepy.Api project
	dotnet run --project TrappyKeepy.Api