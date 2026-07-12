defmodule JapiWeb.FloorController do
  use JapiWeb, :controller

  plug :check_valid_group

  def index(%Plug.Conn{assigns: %{:groupId => groupId}} = conn, _) do
    {:ok, g} = Japi.Groups.get_group(groupId)
    json(conn, %{group: g})
  end

  # Handle hold request with optional priority
  defp handle_hold_request(conn, groupId, userId, priority \\ 1) do
    case Japi.Groups.hold_group(groupId, userId, priority) do
      :ok ->
        conn
        |> put_status(200)
        |> json(%{message: "Floor obtained by #{userId} for group #{groupId}"})

      {:error, {:invalid_hold, _err}} ->
        conn
        |> put_status(409)
        |> json(%{
          message: "Floor is currently held by another user"
        })
    end
  end

  def request(%Plug.Conn{assigns: %{:groupId => groupId}} = conn, %{
        "userId" => uid,
        "priority" => priority
      })
      when is_integer(priority) do
    handle_hold_request(conn, groupId, uid, priority)
  end

  def request(%Plug.Conn{assigns: %{:groupId => groupId}} = conn, %{"userId" => uid}) do
    handle_hold_request(conn, groupId, uid)
  end

  # Request to hold without uid
  def request(conn, _params) do
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
        |> put_status(500)
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
