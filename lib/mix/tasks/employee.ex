defmodule Mix.Tasks.Employee do
  @moduledoc "Print employee milestone anniversaries"
  @shortdoc "Print employee milestone anniversaries. Ex. mix employee employee_data.csv 2020-10-10"

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    [filename, run_date] = args
    Mix.shell().info(Employee.run(filename, run_date))
  end
end
