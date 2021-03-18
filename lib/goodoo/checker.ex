defmodule Goodoo.Checker do
  @moduledoc """
  Behaviour for implementing a checker.

  Goodoo aims to makes it simple to create a checker. There are 2 callbacks that
  require implementation.

      defmodule MyHTTPChecker do
        @behaviour Goodoo.Checker

        @impl true
        def init(options) do
          options
        end

        @impl true
        def perform(options) do
          case HTTPClient.get("https://external-service.net/ping") do
            {:ok, 200, "OK"} ->
              :healthy

            {:ok, 503, "Service unavailable"} ->
              :unhealthy

            {:error, :timeout} ->
              :degraded
          end
        end
      end

  Configure it in your Goodoo module:

      checkers = %{
        "external_service" => {MyHTTPChecker, []}
      }

      children = [
        ...,
        {MyHealthCheck, checkers}
      ]

      Supervisor.start_link(children, strategy: :one_for_one, name: MyApp)

  Please check out `Goodoo.Checker.Redix` or `Goodoo.Checker.EctoSQL` to see a working example.

  """

  # Make sure GenServer does not generate documentation for child_spec/1.
  @doc false
  use GenServer

  alias Goodoo.Storage

  @type checker_state() :: any()
  @type name() :: String.t()
  @type health_state() :: :healthy | :unhealthy | :degraded | :init

  @doc """
  Initiates the checker with the given options.
  """
  @callback init(options :: Keyword.t()) :: checker_state()

  @doc """
  Performs the check.
  """
  @callback perform(checker_state()) :: health_state()

  @enforce_keys [
    :name,
    :checker_module,
    :checker_state,
    :storage_name,
    :intervals
  ]
  defstruct @enforce_keys

  @default_intervals %{
    init: 0,
    unhealthy: 3_000,
    degraded: 10_000,
    healthy: 60_000
  }

  @doc false
  def start_link(init_args) do
    GenServer.start_link(__MODULE__, init_args)
  end

  @impl true
  def init({checker_name, checker_module, storage_name, options}) do
    Storage.report(storage_name, checker_name, :init)

    {intervals, options} = Keyword.pop(options, :intervals, %{})

    checker_state = checker_module.init(options)

    state = %__MODULE__{
      storage_name: storage_name,
      checker_module: checker_module,
      checker_state: checker_state,
      intervals: intervals,
      name: checker_name
    }

    schedule_perform(0)

    {:ok, state}
  end

  @impl true
  def handle_info(:perform, state) do
    %__MODULE__{
      storage_name: storage_name,
      intervals: intervals,
      checker_module: checker_module,
      checker_state: checker_state,
      name: name
    } = state

    health_state = checker_module.perform(checker_state)

    :ok = Storage.report(storage_name, name, health_state)

    health_state
    |> determine_interval(intervals)
    |> schedule_perform()

    {:noreply, state}
  end

  defp schedule_perform(interval) do
    Process.send_after(self(), :perform, interval)
  end

  defp determine_interval(health_state, intervals) do
    case intervals do
      %{^health_state => interval} -> interval
      _ -> Map.fetch!(@default_intervals, health_state)
    end
  end
end
