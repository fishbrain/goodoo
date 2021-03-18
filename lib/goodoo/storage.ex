defmodule Goodoo.Storage do
  @moduledoc false

  def new(table) do
    :ets.new(table, [:named_table, :set, :public, read_concurrency: true])
    :ok
  end

  def report(table, name, state, reported_at \\ DateTime.utc_now()) do
    :ets.insert(table, {name, state, reported_at})

    :ok
  end

  def list(table) do
    table
    |> :ets.tab2list()
    |> Map.new(fn {name, health_state, reported_at} ->
      {name, {health_state, reported_at}}
    end)
  end

  def get(table, name) do
    case :ets.lookup(table, name) do
      [{^name, health_state, reported_at}] ->
        {health_state, reported_at}

      _ ->
        nil
    end
  end

  def get_storage_name(module) when is_atom(module) do
    Module.concat([module, Storage])
  end
end
