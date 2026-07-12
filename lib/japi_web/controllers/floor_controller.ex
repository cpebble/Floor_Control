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

      {:error, {:group_not_found, msg}} ->
        conn
        |> put_status(404)
        |> json(%{message: msg})

      {:error, error} ->
        conn
        |> put_status(500)
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

  def delete(conn, %{"groupId" => groupId}) do
    case Japi.Groups.check_group(groupId) do
      {:error, {:group_not_found, msg}} ->
        conn
        |> put_status(404)
        |> json(%{message: msg})

      :ok ->
        :ok = Japi.Groups.delete_group(groupId)

        conn
        |> put_status(200)
        |> json(%{message: "Group #{groupId} scheduled for deletion"})
    end
  end
end
