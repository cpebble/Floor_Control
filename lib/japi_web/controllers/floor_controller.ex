defmodule JapiWeb.FloorController do
  use JapiWeb, :controller

  def index(conn, _params) do
    groups = Japi.Groups.list_groups()
    json(conn, groups)
  end

  def details(conn, %{"groupId" => groupid}) do
    case Japi.Groups.get_group(groupid) do
      {:ok, groupinfo} ->
        json(conn, groupinfo)

      {:error, error} ->
        conn
        |> put_status(509)
        |> json(%{error: inspect(error)})
    end
  end

  @doc """
  Endpoint when creating a new group
  """
  def create(conn, %{"groupId" => groupid}) do
    case Japi.Groups.start_group(groupid) do
      :ok ->
        put_status(conn, 201)
        |> json(%{success: true})
      {:error, {:group_exists, _}} ->
        conn
        |> put_status(401)
        |> json(%{message: "Group already exists"})
      {:error, error} ->
        conn
        |> put_status(401)
        |> json(%{message: inspect(error)})
      end
  end
end
