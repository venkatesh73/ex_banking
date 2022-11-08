defmodule ExBankingTest do
  use ExUnit.Case

  alias ExBanking

  describe "create_user/1" do
    test "create a new user" do
      assert ExBanking.create_user("Jhon") == :ok
    end

    test "try to create same user again" do
      user = "Jhonny"
      assert ExBanking.create_user(user) == :ok
      assert ExBanking.create_user(user) == {:error, :user_already_exists}
    end

    test "creates user case sensitive" do
      assert ExBanking.create_user("jhon") == :ok
      assert ExBanking.create_user("JHON") == :ok
    end
  end

  describe "deposit/3" do
    test "deposit amount successfully for user" do
      user = "Jane"
      assert ExBanking.create_user(user) == :ok
      assert ExBanking.deposit(user, 100.50, "usd") == {:ok, 100.5}
    end

    test "depost fails for user doesn't exist" do
      assert ExBanking.deposit("James", 100, "INR") == {:error, :user_does_not_exist}
    end

    test "deposit fails at wrong arguments" do
      assert :ok == ExBanking.create_user("William")
      assert ExBanking.deposit("William", "&*256024", "INR") == {:error, :wrong_arguments}
      assert ExBanking.deposit("William", -101.52, "INR") == {:error, :wrong_arguments}
    end

    test "deposit performed if there are less requests at the same time" do
      user = "Dinesh"

      :ok = ExBanking.create_user(user)

      refute deposit_load_test(user, 5)
    end

    test "deposit not performed if there are too many requests" do
      user = "Venkatesh"

      :ok = ExBanking.create_user(user)

      assert deposit_load_test(user, 500)
    end
  end

  describe "withdraw/3" do
    test "successfully withdraw from user balance" do
      :ok = ExBanking.create_user("Penny")
      {:ok, 500.0} = ExBanking.deposit("Penny", 500, "usd")
      assert ExBanking.withdraw("Penny", 100, "usd") == {:ok, 400.0}
    end

    test "returns error when try to withdraw greater than the available balance" do
      :ok = ExBanking.create_user("howard")
      assert ExBanking.withdraw("howard", 1000, "usd") == {:error, :not_enough_money}
      assert ExBanking.withdraw("howard", 1000, "INR") == {:error, :not_enough_money}
    end

    test "error when invalid amount is given for withdraw" do
      :ok = ExBanking.create_user("Sheldon")
      assert ExBanking.withdraw("Sheldon", -1000, "usd") == {:error, :wrong_arguments}
      assert ExBanking.withdraw("Sheldon", "+*/-1000", "usd") == {:error, :wrong_arguments}
    end

    test "returns user doesn't exists when invalid user is given for withdraw" do
      assert ExBanking.withdraw("keith", 1000, "usd") == {:error, :user_does_not_exist}
    end

    test "withdrawal performed if there are less requests at the same time" do
      user = "Shijith"

      :ok = ExBanking.create_user(user)

      refute withdrawal_load_test(user, 5)
    end

    test "withdrawal not performed if there are too many requests" do
      user = "Varun"

      :ok = ExBanking.create_user(user)

      assert withdrawal_load_test(user, 500)
    end
  end

  describe "get_balance/2" do
    test "successfully retrieves users balance" do
      :ok = ExBanking.create_user("Bernad")
      {:ok, 500.0} = ExBanking.deposit("Bernad", 500, "usd")
      assert ExBanking.get_balance("Bernad", "usd") == {:ok, 500.0}
    end

    test "returns error when try to withdraw invalid currency" do
      :ok = ExBanking.create_user("Kuthrapalli")
      {:ok, 500.0} = ExBanking.deposit("Kuthrapalli", 500, "usd")
      assert ExBanking.get_balance("Kuthrapalli", "rus") == {:error, :wrong_arguments}
    end

    test "returns user doesn't exists when invalid user is given for withdraw" do
      assert ExBanking.withdraw("Yadvik", 1000, "usd") == {:error, :user_does_not_exist}
    end

    test "Getbalance performed if there are less requests at the same time" do
      user = "Sathvik"

      :ok = ExBanking.create_user(user)

      refute get_balance_load_test(user, 5)
    end

    test "Getbalance not performed if there are too many requests" do
      user = "Sharma"

      :ok = ExBanking.create_user(user)

      assert get_balance_load_test(user, 500)
    end
  end

  describe "send/4" do
    test "successfully transfers amount to receiver" do
      :ok = ExBanking.create_user("UserA")
      :ok = ExBanking.create_user("UserB")
      {:ok, 500.0} = ExBanking.deposit("UserA", 500, "usd")

      assert ExBanking.send("UserA", "UserB", 200, "usd") == {:ok, 300.0, 200.0}
    end

    test "returns error on invalid amount transfers amount to receiver" do
      :ok = ExBanking.create_user("UserC")
      :ok = ExBanking.create_user("UserD")
      {:ok, 500.0} = ExBanking.deposit("UserC", 500, "usd")

      assert ExBanking.send("UserC", "UserD", "-*//200", "usd") == {:error, :wrong_arguments}
    end

    test "returns error when doesn't have enough balance" do
      :ok = ExBanking.create_user("UserE")
      :ok = ExBanking.create_user("UserF")
      {:ok, 500.0} = ExBanking.deposit("UserE", 500, "usd")

      assert ExBanking.send("UserE", "UserF", 1000, "usd") == {:error, :not_enough_money}
    end

    test "returns error when sender doesn't exists" do
      assert ExBanking.send("UE", "UF", 1000, "usd") == {:error, :sender_does_not_exist}
    end

    test "returns error when receiver doesn't exists" do
      :ok = ExBanking.create_user("UG")
      assert ExBanking.send("UG", "UH", 1000, "usd") == {:error, :receiver_does_not_exist}
    end

    test "Send performed if there are less requests at the same time" do
      user = "UI"

      :ok = ExBanking.create_user(user)

      refute sender_load_test(user, 5)
    end

    test "Send not performed if there are too many requests" do
      user = "UJ"

      :ok = ExBanking.create_user(user)

      assert sender_load_test(user, 500)
    end
  end

  def deposit_load_test(user, max_limit) do
    1..max_limit
    |> Enum.map(fn _ -> Task.async(fn -> ExBanking.deposit(user, 100, "usd") end) end)
    |> Enum.map(&Task.await/1)
    |> Enum.any?(&(&1 == {:error, :too_many_requests_to_user}))
  end

  def withdrawal_load_test(user, max_limit) do
    1..max_limit
    |> Enum.map(fn _ -> Task.async(fn -> ExBanking.withdraw(user, 100, "usd") end) end)
    |> Enum.map(&Task.await/1)
    |> Enum.any?(&(&1 == {:error, :too_many_requests_to_user}))
  end

  def get_balance_load_test(user, max_limit) do
    1..max_limit
    |> Enum.map(fn _ -> Task.async(fn -> ExBanking.get_balance(user, "usd") end) end)
    |> Enum.map(&Task.await/1)
    |> Enum.any?(&(&1 == {:error, :too_many_requests_to_user}))
  end

  def sender_load_test(user, max_limit) do
    1..max_limit
    |> Enum.map(fn _ -> Task.async(fn -> ExBanking.send(user, "AB", 100, "usd") end) end)
    |> Enum.map(&Task.await/1)
    |> Enum.any?(&(&1 == {:error, :too_many_requests_to_sender}))
  end
end
