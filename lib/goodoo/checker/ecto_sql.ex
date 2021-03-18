if Code.ensure_loaded?(Ecto.Adapters.SQL) do
  defmodule Goodoo.Checker.EctoSQL do
    @moduledoc """
    A Goodoo checker for `Ecto`.

    This checker checks if the database is responsive by invoking a
    light-weight SQL call to the configured `Ecto.Repo`.

    ### Options

    * `repo` - the repo module.

    """

    @behaviour Goodoo.Checker

    @impl true
    def init(options), do: Keyword.fetch!(options, :repo)

    @impl true
    def perform(repo) do
      if Process.whereis(repo) do
        try do
          case Ecto.Adapters.SQL.query(repo, "SELECT 1") do
            {:ok, _} ->
              :healthy

            {:error, _} ->
              :unhealthy
          end
        rescue
          DBConnection.ConnectionError -> :degraded
        end
      else
        :unhealthy
      end
    end
  end
end
