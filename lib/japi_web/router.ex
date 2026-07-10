defmodule JapiWeb.Router do
  use JapiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/groups", JapiWeb do
    pipe_through :api

    # Listing/Adding groups
    get "/", FloorController, :index
    get "/:groupId", FloorController, :details
    post "/:groupId", FloorController, :create

    
    # Interacting with a group
    get "/:groupId/floor", GroupController, :index
    post "/:groupId/floor", GroupController, :request
    delete "/:groupId/floor/:userId", GroupController, :release

  end

end
