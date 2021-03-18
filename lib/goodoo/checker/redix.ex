if Code.ensure_loaded?(Redix) do
  defmodule Goodoo.Checker.Redix do
    @moduledoc """
    A Goodoo checker for `Redix`.

    This checker checks if Redis is responsive by sending a PING command
    to Redis and expecting a PONG.

    ### Options

    * `connection` - the Redix connection name.

    """

    @behaviour Goodoo.Checker

    @impl true
    def init(options), do: options

    @impl true
    def perform(options) do
      conn = Keyword.fetch!(options, :connection)

      if Process.whereis(conn) do
        case Redix.command(conn, ["PING"]) do
          {:ok, "PONG"} -> :healthy
          {:error, %Redix.ConnectionError{}} -> :unhealthy
        end
      else
        :unhealthy
      end
    end
  end
end
