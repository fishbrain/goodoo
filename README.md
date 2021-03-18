# Goodoo

Goodoo is a simple, robust, and highly customizable health check solution written in Elixir.

## Installation

Add `:goodoo` to your Mix project.

```elixir
def deps() do
  [{:goodoo, "~> 0.1"}]
end
```

## Overview

Full documentation can be found on [Hex][hex-doc].

Goodoo works by periodically checking the availablity of the sub-systems based
on your configuration, and provides a few APIs to retrieves the report.

To start using Goodoo, create a module:

```elixir
defmodule MyHealthCheck do
  use Goodoo
end
```

After that, add the module with the desired checkers to the supervisor tree.
Please see the "Checkers" section for all currently supported checkers.

```elixir
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
```

Allez, hop! You are "goodoo" to go. To retrieve the health check report,
`list_health_states/1` and `get_health_state/2` can be used.

Usually you might want to expose an HTTP endpoint for some uptime checkers e.g.
AWS ALB, Pingdom, etc. It can be easily done with Plug or Phoenix controller.

### Plug integration

```elixir
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
```

### Phoenix integration

```elixir
defmodule HealthController do
  use MyWeb, :controller

  def index(conn, _params) do
    healthy? =
      Enum.all?(
        Goodoo.list_health_states(MyHealthCheck),
        fn {_checker_name, {state, _last_checked_at}} ->
          state == :healthy
        end
      )

    conn = put_status(conn, 200)

    if healthy? do
      text(conn, "Everything is 200 OK")
    else
      text(conn, "Something is on fire!")
    end
  end
end
```

### "Goodoo" to know

Goodoo is the local name of [Murray Cod][murray-cod] in Australia. Here is a picture of it.

![goodoo](./goodoo.jpg)

## Development

Make sure you have [Elixir installed][elixir-installation-guide].

1. Fork the project.
2. Run `mix deps.get` to fetch dependencies.
3. Run `mix test`.

## Contributing

If you have any ideas or suggestions, feel free to submit [an
issue][goodoo-issue] or [a pull request][goodoo-pr].

## License

MIT


[elixir-installation-guide]: https://elixir-lang.org/install.html
[hex-doc]: https://hexdocs.pm/goodoo
[goodoo-issue]: https://github.com/fishbrain/goodoo/issues
[goodoo-pr]: https://github.com/fishbrain/goodoo/pulls
[murray-cod]: https://en.wikipedia.org/wiki/Murray_cod
