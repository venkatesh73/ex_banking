defmodule ExBankingTest do
  use ExUnit.Case

  alias ExBanking

  describe "create_user/1" do
    test "create a new user" do
      assert :ok == ExBanking.create_user("Jhon")
    end

    test "try to create same user again" do
      user = "Jhonny"
      assert :ok == ExBanking.create_user(user)
      assert {:error, :user_already_exists} == ExBanking.create_user(user)
    end

    test "creates user case sensitive" do
      assert :ok == ExBanking.create_user("jhon")
      assert :ok == ExBanking.create_user("JHON")
    end
  end
end
