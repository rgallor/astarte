#
# This file is part of Astarte.
#
# Copyright 2020 Ispirata Srl
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

defmodule Astarte.AppEngine.APIWeb.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(_arg) do
    children = [
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000},
      {TelemetryMetricsPrometheus.Core, metrics: metrics()}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # VM Metrics
      last_value("vm.memory.total"),
      last_value("vm.memory.processes_used"),
      last_value("vm.memory.processes"),
      last_value("vm.memory.system"),
      last_value("vm.memory.atom"),
      last_value("vm.memory.atom_used"),
      last_value("vm.memory.ets"),
      last_value("vm.memory.code"),
      last_value("vm.system_counts.process_count"),
      last_value("vm.system_counts.atom_count"),
      last_value("vm.system_counts.port_count"),
      last_value("vm.total_run_queue_lengths.total"),
      last_value("vm.total_run_queue_lengths.cpu"),
      last_value("vm.total_run_queue_lengths.io"),
      last_value("vm.refresh"),

      # Phoenix/Plug metrics
      counter("plug_adapter.call.exception.count",
        tags: [:kind, :plug]
      ),
      distribution("phoenix.endpoint.stop.duration",
        unit: {:native, :second},
        tags: [:controller, :method],
        tag_values: &extract_phoenix_buckets_metadata/1,
        reporter_options: [
          buckets: [
            0.00001,
            0.000025,
            0.00005,
            0.0001,
            0.00025,
            0.0005,
            0.001,
            0.0025,
            0.005,
            0.01,
            0.025,
            0.05,
            0.1,
            0.25,
            0.5,
            1.0,
            2.5,
            5.0,
            10.0
          ]
        ]
      ),
      counter("phoenix.endpoint.stop.count",
        tags: [:status],
        tag_values: &extract_status/1
      ),
      counter("astarte.appengine.api.calls.count",
        tags: [:realm]
      ),
      counter("phoenix.router_dispatch.stop.count",
        tags: [:method, :route],
        tag_values: &extract_router_tags/1
      ),

      # Custom metrics
      counter("astarte.appengine.device.message_sent.count",
        tags: [:realm],
        description: "AppEngine sent messages count."
      ),
      counter("astarte.appengine.device.message_sent.exchanged_bytes",
        tags: [:realm],
        description: "AppEngine exchanged bytes count."
      ),
      counter("astarte.appengine.channels.room_opened.count",
        tags: [:realm],
        description: "AppEngine opened rooms count."
      ),
      counter("astarte.appengine.channels.room_closed.count",
        tags: [:realm],
        description: "AppEngine closed rooms count."
      ),
      counter("astarte.appengine.channels.event_sent.count",
        tags: [:realm],
        description: "AppEngine sent events count."
      ),
      counter(
        "astarte.appengine.channels.event_discarded.count",
        tags: [:realm],
        description: "AppEngine discarded events count."
      ),
      last_value(
        "astarte.appengine.service.health",
        tags: [:consistency_level],
        description: "Database connection state: 1 if able to query, 0 if not."
      )
    ]
  end

  defp periodic_measurements do
    [
      # A module, function and arguments to be invoked periodically.
      # This function must call :telemetry.execute/3 and a metric must be added above.
      # {MyApp, :count_users, []}
    ]
  end

  defp extract_phoenix_buckets_metadata(%{
         conn: %{private: %{phoenix_controller: controller}, method: method}
       }) do
    %{controller: controller, method: method}
  end

  # This handles the cases where we don't have a :phoenix_controller key in conn.private
  defp extract_phoenix_buckets_metadata(%{conn: %{method: method}}) do
    %{controller: "unknown", method: method}
  end

  defp extract_status(%{conn: %{status: status}}) do
    %{status: status}
  end

  defp extract_router_tags(%{conn: %{method: method}, route: route}) do
    %{method: method, route: route}
  end
end
