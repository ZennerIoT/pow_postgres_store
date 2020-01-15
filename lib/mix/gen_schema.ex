defmodule Mix.Tasks.Pow.Postgres.Gen.Schema do
  use Mix.Task

  @flags [
    datetime_type: :string,
    schema_name: :string,
    schema_module_name: :string,
    module_prefix: :string
  ]

  @defaults [
    datetime_type: ":utc_datetime",
    schema_name: "pow_store",
    schema_module_name: "Schema",
    module_prefix: "Pow.Postgres"
  ]

  require EEx
  template_file = Path.join([__DIR__, "../templates/schema.ex.eex"])
  EEx.function_from_file(:defp, :render_schema, template_file, [:assigns])

  migrations = "../templates/migrations/"

  @migrations Path.join([__DIR__, migrations]) |> File.ls!() |> Enum.map(fn file -> %{
    source: Path.join([__DIR__, migrations, file]),
    target: "priv/repo/migrations/" <> String.replace_trailing(file, ".eex", ""),
    fun_name: ("render_migration_" <> String.replace_trailing(file, ".exs.eex", "")) |> String.to_atom()
  } end)

  for migration <- @migrations do
    EEx.function_from_file(:def, migration.fun_name, migration.source, [:assigns])
  end

  def run(args) do
    {options, [filename], errors} = OptionParser.parse(args, strict: @flags)
    assigns =
      Keyword.merge(@defaults, options)
      |> Enum.into(%{})

    create_schema_file(assigns, filename)

    create_migrations(assigns)
  end

  def create_schema_file(assigns, filename) do
    code = render_schema(assigns)
    File.write!(filename, code)
  end

  def create_migrations(assigns) do
    File.mkdir_p!("priv/repo/migrations")
    for migration <- @migrations do
      code = apply(__MODULE__, migration.fun_name, [assigns])
      File.write!(migration.target, code)
    end
  end
end
