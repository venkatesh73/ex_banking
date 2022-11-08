defmodule ExBanking.DynamicSupervisor do
  @moduledoc false

  use DynamicSupervisor

  alias ExBanking.Worker

  @module __MODULE__

  def start_link(_args) do
    DynamicSupervisor.start_link(@module, [], name: @module)
  end

  @impl true
  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @spec create_user(user :: String.t()) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(user) do
    case DynamicSupervisor.start_child(
           @module,
           %{
             :id => user,
             :start => {Worker, :start_link, [String.to_atom(user)]}
           }
         ) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> {:error, :user_already_exists}
    end
  end
end
