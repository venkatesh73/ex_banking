defmodule ExBanking.Supervisor do
  @moduledoc false
  use Supervisor

  alias ExBanking.DynamicSupervisor, as: UserSupervisor

  @module __MODULE__

  def start_link() do
    Supervisor.start_link(@module, [], name: @module)
  end

  def init(_args) do
    children = [{UserSupervisor, []}]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
