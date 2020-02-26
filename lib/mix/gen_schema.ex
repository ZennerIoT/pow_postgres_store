defmodule Mix.Tasks.Pow.Postgres.Gen.Schema do
  use Mix.Task

  @flags [
    datetime_type: :string,
    schema_name: :string,
    schema_module_name: :string,
    module_prefix: :string,
    overwrite: :boolean
  ]

  @defaults [
    datetime_type: ":utc_datetime",
    schema_name: "pow_store",
    schema_module_name: "Schema",
    module_prefix: "Pow.Postgres",
    overwrite: false
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
    {options, [filename], _errors} = OptionParser.parse(args, strict: @flags)
    assigns =
      Keyword.merge(@defaults, options)
      |> Keyword.take([:datetime_type, :schema_name, :schema_module_name, :module_prefix])
      |> Enum.into(%{})

    create_schema_file(assigns, filename, options)

    create_migrations(assigns, options)
  end

  def create_schema_file(assigns, filename, options) do
    code = render_schema(assigns)
    write(filename, code, options)
  end

  def create_migrations(assigns, options) do
    File.mkdir_p!("priv/repo/migrations")
    for migration <- @migrations do
      code = apply(__MODULE__, migration.fun_name, [assigns])
      write(migration.target, code, options)
    end
  end

  def write(filename, code, opts) do
    if not File.exists?(filename) or Keyword.get(opts, :overwrite, false) do
      File.write!(filename, code)
      IO.puts [
        IO.ANSI.green(),
        " * Generated ",
        IO.ANSI.reset(),
        filename
      ]
    else
      IO.puts [
        IO.ANSI.red(),
        " * Failed to generate ",
        IO.ANSI.reset(),
        filename,
        IO.ANSI.red(),
        " - this file already exists. Pass ",
        IO.ANSI.reset(),
        "--overwrite",
        IO.ANSI.red(),
        " to generate this file anyway.",
        IO.ANSI.reset()
      ]
    end
  end
end
