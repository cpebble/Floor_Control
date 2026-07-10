defmodule Japi.Groups do
  use Supervisor

  def start_link(init_args) do
    Supervisor.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  @impl true
  def init(_) do
    children = [
      {Registry, name: Japi.Groups.Registry, keys: :unique},
      {DynamicSupervisor, name: Japi.Groups.GroupSupervisor, strategy: :one_for_one},
      Japi.Groups.Server
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  # Functions
  def start_group(group_id) do
    GenServer.call(Japi.Groups.Server, {:add_group, group_id})
  end

  # A helper function to initialize a list of groups
  def start_groups([group_id | tail]) do
    case Japi.Groups.start_group(group_id) do
      :ok -> start_groups(tail)
      {:error, reason} -> {:error, "Error in intialization: " <> reason}
    end
  end

  def start_groups([]), do: :ok

  def list_groups do
    GenServer.call(Japi.Groups.Server, :list)
  end

  def get_group(group_id) do
    GenServer.call(Japi.Groups.Server, {:get_group, group_id})
  end

  def check_group(group_id) do
    GenServer.call(Japi.Groups.Server, {:check_group, group_id})
  end

  def hold_group(group_id, user_id) do
    GenServer.call(Japi.Groups.Server, {:hold_group, group_id, user_id})
  end
  def release_group(group_id, user_id) do
    GenServer.call(Japi.Groups.Server, {:release_group, group_id, user_id})
  end
end

defmodule Japi.Groups.Server do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, MapSet.new(), name: __MODULE__)
  end

  # Callbacks
  @impl true
  def init(initial_state) do
    # IO.puts("Initialized GroupServer with: #{inspect channels}")
    # groups = for name <- channels, into: %{}, do: {name, %{}}
    {:ok, initial_state}
  end

  @impl true
  def handle_call(:list, _from, state) do
    groupIds = MapSet.to_list(state)
    {:reply, groupIds, state}
  end

  @impl true
  def handle_call({:add_group, name}, _from, state) do
    # Check if name is taken
    cond do
      not is_bitstring(name) ->
        {:reply, {:error, {:invalid_name, "Invalid type passed as name"}}, state}

      not String.valid?(name) ->
        {:reply, {:error, {:invalid_name, "Invalid type passed as name"}}, state}

      name in state ->
        {:reply, {:error, {:group_exists, "Group #{name} already exists"}}, state}

      true ->
        case DynamicSupervisor.start_child(
               Japi.Groups.GroupSupervisor,
               {Japi.Groups.Group, name: via(name)}
             ) do
          # Only add to state if child successfully starts
          {:ok, _} -> {:reply, :ok, MapSet.put(state, name)}
          {:error, err} -> {:reply, {:error, {:unhandled_error, err}}, state}
        end
    end
  end

  @impl true
  def handle_call({:get_group, group_id}, _from, state) do
    if group_id in state do
      {:reply, {:ok, Japi.Groups.Group.get(via(group_id))}, state}
    else
      {:reply, {:error, {:group_not_found, "Group #{group_id} not found"}}, state}
    end
  end

  @impl true
  def handle_call({:check_group, group_id}, _from, state) do
    if group_id in state do
      {:reply, :ok, state}
    else
      {:reply, {:error, {:group_not_found, "Group #{group_id} not found"}}, state}
    end
  end

  @impl true
  def handle_call({:hold_group, gid, uid}, _from, state) do
    case Japi.Groups.Group.hold(via(gid), uid) do
      :ok -> {:reply, :ok, state}
      :invalid -> {:reply, {:error, {:invalid_hold, "Couldn't get hold"}}, state}
    end
  end

  @impl true
  def handle_call({:release_group, gid, uid}, _from, state) do
    case Japi.Groups.Group.release(via(gid), uid) do
      :ok -> {:reply, :ok, state}
      :invalid -> {:reply, {:error, {:invalid_release, "User doesn't hold group"}}, state}
    end

  end

  @impl true
  def handle_cast({_cmd, _opts}, state) do
    {:noreply, state}
  end

  # Privates
  defp via(name), do: {:via, Registry, {Japi.Groups.Registry, name}}
end

defmodule Japi.Groups.Group do
  use Agent

  defmodule Group do
    @derive {Jason.Encoder, only: [:held_by]}
    defstruct held_by: nil
  end

  def start_link(opts) do
    Agent.start_link(fn -> %Group{} end, opts)
  end

  def get(pid) do
    Agent.get(pid, & &1)
  end

  def hold(pid, uid) do
    updatef = fn
      %Group{held_by: nil} -> {:ok, %Group{held_by: uid}}
      %Group{held_by: uid_} when uid_ == uid -> {:ok, %Group{held_by: uid}}
      group -> {:invalid, group}
    end

    Agent.get_and_update(pid, updatef)
  end

  def release(pid, uid) do
    updatef = fn
      %Group{held_by: nil} -> {:ok, %Group{held_by: nil}}
      %Group{held_by: uid_} when uid_ == uid -> {:ok, %Group{held_by: nil}}
      group -> {:invalid, group}
    end

    Agent.get_and_update(pid, updatef)
  end
end
