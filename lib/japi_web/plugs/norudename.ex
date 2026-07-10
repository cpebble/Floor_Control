defmodule JapiWeb.Plugs.NoRudeName do
  import Plug.Conn

  def init(default), do: default

  def call(%Plug.Conn{params: params} = conn, _) when not is_map_key(params, "name"),
    do: assign(conn, :name, "Mr Rude")

  def call(%Plug.Conn{params: %{"name" => "Mr Rude"}} = conn, _),
    do: assign(conn, :name, "The Man, The myth, The Legend")

  def call(%Plug.Conn{params: %{"name" => name}} = conn, _),
    do: assign(conn, :name, name)
end
