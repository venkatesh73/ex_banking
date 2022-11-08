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

  def deposit_load_test(user, max_limit) do
    1..max_limit
    |> Enum.map(fn _ -> Task.async(fn -> ExBanking.deposit(user, 100, "usd") end) end)
    |> Enum.map(&Task.await/1)
    |> Enum.any?(&(&1 == {:error, :too_many_requests_to_user}))
  end
end
