defmodule ExBanking.Worker do
  @moduledoc """
  Banking worker to handle and maintain transactions for induvidual users
  """
  use GenServer

  @type response_error ::
          {:error,
           :wrong_arguments
           | :user_already_exists
           | :user_does_not_exist
           | :not_enough_money
           | :sender_does_not_exist
           | :receiver_does_not_exist
           | :too_many_requests_to_user
           | :too_many_requests_to_sender
           | :too_many_requests_to_receiver}

  def start_link(name) do
    GenServer.start_link(__MODULE__, %{}, name: name)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call({:deposit, currency, amount}, _from, state)
      when is_number(amount) and amount > 0 do
    state =
      case state[currency] do
        nil ->
          Map.put(state, currency, amount)

        amount ->
          Map.update!(state, currency, &(&1 + amount))
      end

    {:reply, {:ok, Float.floor(state[currency] / 1, 2)}, state}
  end

  def handle_call({:deposit, _currency, amount}, _from, state)
      when not is_number(amount) or amount < 0 do
    {:reply, {:error, :wrong_arguments}, state}
  end

  @spec deposit(user :: String.t(), amount :: number(), currency :: String.t()) ::
          {:ok, number()} | response_error
  def deposit(user, amount, currency) do
    case get_users_pool_limit(user) do
      {:ok, limit} when limit > 10 ->
        {:error, :too_many_requests_to_user}

      {:ok, _} ->
        GenServer.call(String.to_atom(user), {:deposit, String.to_atom(currency), amount})

      error ->
        error
    end
  end

  defp get_users_pool_limit(user) do
    try do
      {:status, pid, _, _} = :sys.get_status(String.to_atom(user))
      {:message_queue_len, queue_len} = :erlang.process_info(pid, :message_queue_len)
      {:ok, queue_len}
    catch
      :exit, _ -> {:error, :user_does_not_exist}
    end
  end
end
