defmodule GoodooTest do
  use ExUnit.Case, async: false

  defmodule FakeHealthCheck do
    use Goodoo
  end

  defmodule FakeChecker do
    @behaviour Goodoo.Checker

    @impl true
    def init(options), do: options

    @impl true
    def perform(options) do
      test_pid = Keyword.fetch!(options, :test_pid)
      state = Keyword.fetch!(options, :state)

      send(test_pid, state)

      state
    end
  end

  test "performs checks periodically" do
    test_pid = self()

    checkers = %{
      "healthy" => {FakeChecker, [test_pid: test_pid, state: :healthy]},
      "unhealthy" => {FakeChecker, [test_pid: test_pid, state: :unhealthy]}
    }

    start_supervised!({FakeHealthCheck, checkers})

    assert_receive :healthy
    assert_receive :unhealthy
    refute_receive _

    assert %{
             "healthy" => {:healthy, %DateTime{}},
             "unhealthy" => {:unhealthy, %DateTime{}}
           } = Goodoo.list_health_states(FakeHealthCheck)

    assert {:healthy, %DateTime{}} = Goodoo.get_health_state(FakeHealthCheck, "healthy")
    assert {:unhealthy, %DateTime{}} = Goodoo.get_health_state(FakeHealthCheck, "unhealthy")
  end

  for state <- [:healthy, :unhealthy, :degraded] do
    test "takes configured interval for #{state} into account" do
      state = unquote(state)

      test_pid = self()
      intervals = %{state => 500}

      checkers = %{
        "healthy" => {FakeChecker, [test_pid: test_pid, state: state, intervals: intervals]}
      }

      start_supervised!({FakeHealthCheck, checkers})

      assert_receive ^state

      Process.sleep(500)

      assert_receive ^state
    end
  end
end
