defmodule JapiWeb.Router do
  use JapiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/groups", JapiWeb do
    pipe_through :api

    # Listing/Adding groups
    get "/", GroupController, :index
    get "/:groupId", GroupController, :details
    post "/:groupId", GroupController, :create
    delete "/:groupId", GroupController, :delete

    
    # Interacting with a group
    get "/:groupId/floor", FloorController, :index
    post "/:groupId/floor", FloorController, :request
    delete "/:groupId/floor/:userId", FloorController, :release

  end

end
