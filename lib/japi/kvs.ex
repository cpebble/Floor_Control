defmodule Japi.KVs do
  @moduledoc """
  The main floor controller Store

  Requires an initial value of a list of atoms representing room names
  """
  use Agent

  defmodule Room do
    @derive {Jason.Encoder, only: [:held_by]}
    defstruct held_by: nil
  end

  def start_link(initial_value) do
    IO.puts("Starting KV Store")

    Agent.start_link(fn -> for name <- initial_value, into: %{}, do: {name, %Room{}} end,
      name: __MODULE__
    )
  end

  def rooms() do
    Agent.get(__MODULE__, & &1)
  end

  def increment do
    Agent.update(__MODULE__, &(&1 + 1))
  end
end

