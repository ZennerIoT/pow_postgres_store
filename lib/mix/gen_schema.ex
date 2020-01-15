defmodule Mix.Tasks.Pow.Postgres.Gen.Schema do
  use Mix.Task

  @flags [
    datetime_type: :string,
    schema_name: :string,
    module_name: :string
  ]

  @defaults [
    datetime_type: ":utc_datetime",
    schema_name: "pow_store",
    module_name: "Pow.Postgres.Schema"
  ]

  def run(args) do
    {options, [filename], errors} = OptionParser.parse(args, strict: @flags)
    assigns =
      Keyword.merge(@defaults, options)
      |> Enum.into(%{})

    code = render_schema(assigns)
    File.write!(filename, code)
  end

  require EEx
  template_file = Path.join([__DIR__, "../schema.ex.eex"])
  EEx.function_from_file(:defp, :render_schema, template_file, [:assigns])
end
