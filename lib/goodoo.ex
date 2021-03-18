defmodule Goodoo do
  @moduledoc """
  Goodoo is a simple, robust, and highly customizable health check solution written in Elixir.

  Goodoo works by periodically checking the availablity of the sub-systems based
  on your configuration, and provides a few APIs to retrieves the report.

  To start using Goodoo, create a module:

      defmodule MyHealthCheck do
        use Goodoo
      end

  After that, add the module with the desired checkers to the supervisor tree.
  Please see the "Checkers" section for all currently supported checkers.

      checkers = %{
        "primary" => {Goodoo.Checker.EctoSQL, repo: MyPrimaryRepo},
        "replica" => {Goodoo.Checker.EctoSQL, repo: MyReplicaRepo},
        "persistent_cache" => {Goodoo.Checker.Redix, connection: MyCache}
      }

      children = [
        MyPrimaryRepo,
        MyReplicaRepo,
        MyCache,
        ...,
        {MyHealthCheck, checkers},
        MyEndpoint
      ]

      Supervisor.start_link(children, strategy: :one_for_one, name: MyApp)

  Allez, hop! You are "goodoo" to go. To retrieve the health check report,
  `list_health_states/1` and `get_health_state/2` can be used.

  Usually you might want to expose an HTTP endpoint for some uptime checkers e.g.
  AWS ALB, Pingdom, etc. It can be easily done with Plug.

      defmodule MyRouter do
        use Plug.Router

        plug :match
        plug :dispatch

        get "/health" do
          healthy? =
            Enum.all?(
              Goodoo.list_health_states(MyHealthCheck),
              fn {_checker_name, {state, _last_checked_at}} ->
                state == :healthy
              end
            )

          if healthy? do
            send_resp(conn, 200, "Everything is 200 OK")
          else
            send_resp(conn, 503, "Something is on fire!")
          end
        end

        get "/health/:checker_name" do
          case Goodoo.get_health_state(MyHealthCheck, checker_name) do
            nil ->
              send_resp(conn, 404, "Not found")

            {state, _last_checked_at} ->
              if state == :healthy do
                send_resp(conn, 200, "Service is doing fine")
              else
                send_resp(conn, 503, "Service is on fire")
              end
          end
        end
      end

  ### Checkers

  Goodoo implemented a few common checkers:

  * `Goodoo.Checker.EctoSQL` - checkers for works with `Ecto.Repo`.
  * `Goodoo.Checker.Redix` - Checker that works with `Redix`.

  For more information, please visit the documentation for them accordingly.

  Goodoo supports customer checkers, please visit `Goodoo.Checker` for more information.

  ### Checker scheduling/interval

  Goodoo schedules checkers based on the last health state. The default intervals are:

  * `:healthy` - next check will be in 30 seconds.
  * `:degraded` - next check will be in 10 seconds.
  * `:unhealthy` - next check will be in 3 seconds.

  You can configure your own strategy with the following example. Please note that missing
  intervals will fall back to the defaults.

      # `:healthy` and `:degraded` will fall back to defaults.
      repo_intervals = %{
        unhealthy: 1_000
      }

      cache_intervals = %{
        unhealthy: 1_000,
        degraded: 5_000,
        healthy: 15_000
      }

      checkers = %{
        "repo" => {Goodoo.Checker.EctoSQL, repo: MyRepo, intervals: repo_intervals},
        "cache" => {Goodoo.Checker.EctoSQL, connection: MyCache, intervals: cache_intervals}
      }

  """

  defmacro __using__(_) do
    quote location: :keep do
      import Goodoo

      def child_spec(checkers) do
        Goodoo.Supervisor.child_spec({__MODULE__, checkers})
      end
    end
  end

  @doc """
  Retrieves all checker statuses of a healthcheck module.
  """
  @spec list_health_states(module()) :: %{
          Goodoo.Checker.name() => {Goodoo.Checker.health_state(), DateTime.t()}
        }
  def list_health_states(module) do
    module
    |> Goodoo.Storage.get_storage_name()
    |> Goodoo.Storage.list()
  end

  @doc """
  Retrieve the checker status by its name of a healthcheck module
  """
  @spec get_health_state(module(), Goodoo.Checker.name()) ::
          {Goodoo.Checker.health_state(), DateTime.t()} | nil
  def get_health_state(module, name) do
    module
    |> Goodoo.Storage.get_storage_name()
    |> Goodoo.Storage.get(name)
  end
end
