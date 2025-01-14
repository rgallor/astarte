#
# This file is part of Astarte.
#
# Copyright 2022 SECO Mind Srl
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

defmodule Astarte.TriggerEngine.Policy.Queries do
  require Logger

  alias Astarte.Core.Realm

  def retrieve_policy_data(realm_name, policy_name) do
    with :ok <- verify_realm_name(realm_name),
         {:ok, policy} <-
           Xandra.Cluster.run(:xandra, fn conn ->
             do_retrieve_policy_data(conn, realm_name, policy_name)
           end) do
      {:ok, policy}
    end
  end

  defp do_retrieve_policy_data(conn, realm_name, policy_name) do
    retrieve_statement =
      "SELECT value FROM #{realm_name}.kv_store WHERE group='trigger_policy' AND key=:policy_name;"

    with {:ok, prepared} <-
           Xandra.prepare(conn, retrieve_statement),
         {:ok, %Xandra.Page{} = page} <-
           Xandra.execute(conn, prepared, %{"policy_name" => policy_name}),
         [%{"value" => policy}] <- Enum.to_list(page) do
      {:ok, policy}
    else
      {:error, %Xandra.Error{} = err} ->
        _ = Logger.warn("Database error: #{inspect(err)}.", tag: "database_error")
        {:error, :database_error}

      {:error, %Xandra.ConnectionError{} = err} ->
        _ =
          Logger.warn("Database connection error: #{inspect(err)}.",
            tag: "database_connection_error"
          )

        {:error, :database_connection_error}
    end
  end

  defp verify_realm_name(realm_name) do
    if Realm.valid_name?(realm_name) do
      :ok
    else
      _ =
        Logger.warn("Invalid realm name.",
          tag: "invalid_realm_name",
          realm: realm_name
        )

      {:error, :realm_not_allowed}
    end
  end
end
