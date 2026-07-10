defmodule Japi.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      JapiWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:japi, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Japi.PubSub},
      # Start a worker by calling: Japi.Worker.start_link(arg)
      # {Japi.Worker, arg},
      # Start to serve requests, typically the last entry
      Japi.Groups,
      JapiWeb.Endpoint
    ]
    
    #Japi.Rooms.start_rooms(["general", "private"])
    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Japi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    JapiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
