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
	@# This will clean the output (both the intermediate (obj) and final output (bin) folders) of the project.
	# ----------
	# Cleaning the output of the previous build.
	dotnet clean TrappyKeepy.Api
	dotnet clean TrappyKeepy.Data
	dotnet clean TrappyKeepy.Domain
	dotnet clean TrappyKeepy.Service
	dotnet clean TrappyKeepy.Test

.PHONY: restore
restore:
	@# This will restore the dependencies and tools of each project.
	# ----------
	# Restoring dependencies and tools.
	dotnet restore TrappyKeepy.Api
	dotnet restore TrappyKeepy.Data
	dotnet restore TrappyKeepy.Domain
	dotnet restore TrappyKeepy.Service
	dotnet restore TrappyKeepy.Test

.PHONY: migrate
migrate:
	@# This will migrate the database using [Flyway](https://flywaydb.org) based on the SQL migration scripts.
	# ----------
	# Migrating the database
	./flyway-8.0.4/flyway -configFiles=flyway.conf migrate

.PHONY: dbscaffold
dbscaffold:
	@# This will create or overwrite the database context class and model classes
	@# based on the current database structure.
	# ----------
	# Scaffolding the database context and model classes
	dotnet ef dbcontext scaffold Name=ConnectionStrings:TKDB_CONN_STRING --project TrappyKeepy.Api --context-namespace TrappyKeepy.Data --namespace TrappyKeepy.Domain.Models --data-annotations --schema tk --context KeepyDbContext --context-dir ../TrappyKeepy.Data/DataBridges --output-dir ../TrappyKeepy.Domain/Models --force Npgsql.EntityFrameworkCore.PostgreSQL

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
	@# This will execute unit tests, after making sure the development database is up to date with migrations.
	# ----------
	# Running unit tests.
	make migrate
	dotnet test --verbosity quiet /p:CollectCoverage=true /p:CoverletOutputFormat=opencover

.PHONY: run
run:
	@# This will run the TrappyKeepy.Api project.
	# ----------
	# Running the TrappyKeepy.Api project
	dotnet run --project TrappyKeepy.Api

.PHONY: publish
publish:
	@# This will compile the application.
	# ----------
	# Compiling the application for release.
	make -C TrappyKeepy.Api publish
	mkdir dist
	mv TrappyKeepy.Api/TrappyKeepy.Api dist/
