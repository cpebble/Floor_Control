defmodule JapiWeb.GroupController do
  use JapiWeb, :controller

  plug :check_valid_group

  def index(%Plug.Conn{assigns: %{:groupId => groupId}} = conn, _) do
    {:ok, g} = Japi.Groups.get_group(groupId)
    json(conn, %{group: g})
  end

  def request(%Plug.Conn{assigns: %{:groupId => groupId}} = conn, %{"userId" => uid}) do
    case Japi.Groups.hold_group(groupId, uid) do
      :ok ->
        conn
        |> put_status(200)
        |> json(%{message: "Floor obtained by #{uid} for group #{groupId}"})

      {:error, {:invalid_hold, _err}} ->
        conn
        |> put_status(409)
        |> json(%{
          message: "Floor is currently held by another user"
        })
    end
  end

  # Request to hold without uid
  def request(conn, _params) do
    IO.puts("Hello")

    conn
    |> put_status(400)
    |> json(%{message: "Invalid request: userId is required"})
  end

  def release(%Plug.Conn{assigns: %{:groupId => groupId}} = conn, %{"userId" => uid}) do
    case Japi.Groups.release_group(groupId, uid) do
      :ok ->
        conn
        |> put_status(200)
        |> json(%{
          message: "Floor released"
        })

      {:error, {:invalid_release, err}} ->
        conn
        |> put_status(403)
        |> json(%{message: err})
    end
  end

  defp check_valid_group(%Plug.Conn{params: %{"groupId" => groupId}} = conn, _) do
    case Japi.Groups.check_group(groupId) do
      :ok ->
        assign(conn, :groupId, groupId)

      {:error, {:group_not_found, msg}} ->
        conn
        |> put_status(404)
        |> json(%{message: msg})
        |> halt()

      {:error, {_, msg}} ->
        conn
        |> put_status(509)
        |> json(%{message: msg})
        |> halt()
    end
  end

  defp check_valid_group(conn, _) do
    conn
    |> put_status(400)
    |> json(%{message: "No GroupId Provided"})
    |> halt()
  end
end
