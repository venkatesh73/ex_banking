defmodule ExBanking do
  @moduledoc """
  Documentation for `ExBanking`.
  """

  alias ExBanking.DynamicSupervisor, as: UserSupervisor
  alias ExBanking.Worker

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

  @spec create_user(user :: String.t()) :: :ok | response_error
  def create_user(user) do
    UserSupervisor.create_user(user)
  end

  @spec deposit(user :: String.t(), amount :: number(), currency :: String.t()) ::
          {:ok, number()} | response_error
  def deposit(user, amount, currency) do
    Worker.deposit(user, amount, currency)
  end

  @spec withdraw(user :: String.t(), amount :: number(), currency :: String.t()) ::
          {:ok, number()} | response_error
  def withdraw(user, amount, currency) do
    Worker.withdraw(user, amount, currency)
  end

  @spec get_balance(user :: String.t(), currency :: String.t()) ::
          {:ok, number()} | response_error
  def get_balance(user, currency) do
    Worker.get_balance(user, currency)
  end

  @spec send(
          from_user :: String.t(),
          to_user :: String.t(),
          amount :: number(),
          currency :: String.t()
        ) :: {:ok, number(), number()} | response_error
  def send(_from_user, _to_user, _amount, _currency) do
    {:error, :sender_does_not_exist}
  end
end
