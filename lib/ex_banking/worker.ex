defmodule ExBanking.Worker do
  @moduledoc """
  Banking worker to handle and maintain transactions for induvidual users
  """
  use GenServer

  def start_link(name) do
    GenServer.start_link(__MODULE__, %{}, name: name)
  end

  def init(state) do
    {:ok, state}
  end
end
