defmodule Employee do
  def run(filename, run_date) do
    {:ok, content} = File.read(filename)
    [_header_line | body_lines] = String.split(content, ~r/\n|\r\n/, trim: true)

    output = process_lines(body_lines, run_date)

    Jason.encode!(output, pretty: true)
  end

  defp process_lines(lines, run_date) do
    employees =
      Enum.reduce(lines, [], fn line, employees ->
        [employee_id, _first_name, _last_name, hire_date, supervisor_id] = String.split(line, ",")

        employee = %{
          employee_id: employee_id,
          # first_name: first_name,
          # last_name: last_name,
          hire_date: hire_date,
          supervisor_id: supervisor_id
        }

        [employee | employees]
      end)

    supervisors_with_direct_reports = Enum.group_by(employees, & &1.supervisor_id)

    supervisors_with_direct_reports_ids = Map.keys(supervisors_with_direct_reports)

    formatted_employees =
      employees
      |> Enum.map(&Map.take(&1, [:employee_id]))
      |> Enum.filter(&(&1.employee_id not in supervisors_with_direct_reports_ids))

    processed_supervisors_with_direct_reports =
      process_supervisors_with_direct_reports(supervisors_with_direct_reports, run_date)

    formatted_employees ++ processed_supervisors_with_direct_reports
  end

  defp process_supervisors_with_direct_reports(supervisors_with_direct_reports, run_date) do
    run_date = Date.from_iso8601!(run_date)

    Enum.map(supervisors_with_direct_reports, fn {supervisor_id, direct_reports} ->
      upcoming_milestones =
        direct_reports
        |> Enum.map(fn employee ->
          hire_date = Date.from_iso8601!(employee.hire_date)
          anniversary_date = calculate_anniversary_date(hire_date, run_date)

          Map.put(employee, :anniversary_date, anniversary_date)
        end)
        |> Enum.sort_by(& &1.anniversary_date, {:asc, Date})
        |> Enum.take(5)
        |> Enum.map(fn employee ->
          %{
            employee_id: employee.employee_id,
            anniversary_date: employee.anniversary_date
          }
        end)

      %{
        supervisor_id: supervisor_id,
        upcoming_milestones: upcoming_milestones
      }
    end)
  end

  defp calculate_anniversary_date(hire_date, run_date) do
    # based on StackOverflow
    # https://stackoverflow.com/questions/39521375/calculating-next-3-year-anniversary-of-employee-based-on-join-date

    period = 5

    %Date{year: hire_year, month: month, day: day} = hire_date
    %Date{year: run_year} = run_date

    year_diff = period * floor((run_year - hire_year) / period)

    cond do
      Date.compare(hire_date, run_date) == :gt ->
        %Date{year: hire_year, month: month, day: day}

      Date.compare(%Date{year: hire_year + year_diff, month: month, day: day}, run_date) == :gt ->
        %Date{year: hire_year + year_diff, month: month, day: day}

      true ->
        %Date{year: hire_year + year_diff + period, month: month, day: day}
    end
  end
end
