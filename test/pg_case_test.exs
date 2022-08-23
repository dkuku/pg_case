defmodule PgCaseTest do
  use ExUnit.Case
  doctest PgCase

  import Ecto.Query, only: [from: 2]
  import PgCase

  alias Ecto.Adapters.SQL
  alias PgCase.Repo

  describe "pg_cond/1" do
    test "correctly expands the macro on all the clauses" do
      query =
        from(r in "rows",
          select: %{
            value:
              pg_cond do
                r.x < 0 -> 0
              else
                r.x
              end
          }
        )

      {query, []} = SQL.to_sql(:all, Repo, query)

      assert query ==
               "SELECT CASE WHEN r0.\"x\" < 0 THEN 0 ELSE r0.\"x\" END FROM \"rows\" AS r0"
    end

    test "correctly expands the macro without else-clause" do
      query =
        from(r in "rows",
          select: %{
            value:
              pg_cond do
                r.x < 0 -> 0
              end
          }
        )

      {query, []} = SQL.to_sql(:all, Repo, query)

      assert query ==
               "SELECT CASE WHEN r0.\"x\" < 0 THEN 0 END FROM \"rows\" AS r0"
    end
  end

  describe "pg_case/2" do
    test "correctly expands the macro on all the clauses" do
      query =
        from(r in "rows",
          select: %{
            value:
              pg_case r.x do
                0 -> false
                1 -> true
              else
                r.x
              end
          }
        )

      {query, []} = SQL.to_sql(:all, Repo, query)

      assert query ==
               "SELECT CASE r0.\"x\" WHEN 0 THEN FALSE WHEN 1 THEN TRUE ELSE r0.\"x\" END FROM \"rows\" AS r0"
    end

    test "correctly expands the macro without else-clause" do
      query =
        from(r in "rows",
          select: %{
            value:
              pg_case r.x do
                0 -> false
                1 -> true
              end
          }
        )

      {query, []} = SQL.to_sql(:all, Repo, query)

      assert query ==
               "SELECT CASE r0.\"x\" WHEN 0 THEN FALSE WHEN 1 THEN TRUE END FROM \"rows\" AS r0"
    end
  end

  describe "pg_if/2" do
    test "correctly expands the macro on all the clauses" do
      query =
        from(r in "rows",
          select: %{value: pg_if(r.x < 0, do: 0, else: 1)}
        )

      {query, []} = SQL.to_sql(:all, Repo, query)

      assert query ==
               "SELECT CASE WHEN r0.\"x\" < 0 THEN 0 ELSE 1 END FROM \"rows\" AS r0"
    end

    test "correctly expands the macro without else-clause" do
      query =
        from(r in "rows",
          select: %{value: pg_if(r.x < 0, do: 0)}
        )

      {query, []} = SQL.to_sql(:all, Repo, query)

      assert query ==
               "SELECT CASE WHEN r0.\"x\" < 0 THEN 0 END FROM \"rows\" AS r0"
    end

    test "raises SyntaxError if no do-clause provided" do
      quoted =
        quote do
          import Ecto.Query, only: [from: 2]
          import PgCase, only: [pg_if: 2]

          from(r in "rows",
            select: %{value: pg_if(r.x < 0, else: 1)}
          )
        end

      assert_raise SyntaxError, fn ->
        Code.compile_quoted(quoted)
      end
    end
  end
end
