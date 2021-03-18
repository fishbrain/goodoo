defmodule Goodoo.Supervisor do
  @moduledoc false

  use Supervisor

  alias Goodoo.Storage

  def start_link({module, _checkers} = init_args) do
    Supervisor.start_link(__MODULE__, init_args, name: module)
  end

  def init({module, checkers}) do
    storage_name = Storage.get_storage_name(module)
    :ok = Storage.new(storage_name)

    children =
      for {checker_name, {checker_module, checker_options}} <- checkers do
        Supervisor.child_spec(
          {Goodoo.Checker, {checker_name, checker_module, storage_name, checker_options}},
          id: String.to_atom(checker_name)
        )
      end

    Supervisor.init(children, strategy: :one_for_one)
  end
end
