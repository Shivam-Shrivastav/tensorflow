/* Copyright 2020 The TensorFlow Authors. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
==============================================================================*/

#include "tensorflow/core/profiler/convert/xplane_to_op_stats.h"

#include "absl/strings/str_cat.h"
#include "tensorflow/core/platform/env.h"
#include "tensorflow/core/platform/path.h"
#include "tensorflow/core/platform/status.h"
#include "tensorflow/core/platform/test.h"
#include "tensorflow/core/platform/types.h"
#include "tensorflow/core/profiler/protobuf/diagnostics.pb.h"
#include "tensorflow/core/profiler/protobuf/op_metrics.pb.h"
#include "tensorflow/core/profiler/protobuf/op_stats.pb.h"
#include "tensorflow/core/profiler/protobuf/steps_db.pb.h"
#include "tensorflow/core/profiler/protobuf/tf_function.pb.h"
#include "tensorflow/core/profiler/protobuf/xplane.pb.h"
#include "tensorflow/core/profiler/utils/group_events.h"
#include "tensorflow/core/profiler/utils/xplane_builder.h"
#include "tensorflow/core/profiler/utils/xplane_schema.h"
#include "tensorflow/core/profiler/utils/xplane_test_utils.h"

namespace tensorflow {
namespace profiler {
namespace {

TEST(ConvertXPlaneToOpStats, PerfEnv) {
  XSpace space;
  constexpr double kMaxError = 0.01;
  constexpr int kClockRateKHz = 1530000;
  constexpr int kCoreCount = 80;
  constexpr uint64 kMemoryBandwidthBytesPerSecond = 900 * 1e9;
  // Volta.
  constexpr int kComputeCapMajor = 7;
  constexpr int kComputeCapMinor = 0;

  XPlaneBuilder device_plane(
      GetOrCreateGpuXPlane(&space, /*device_ordinal=*/0));
  device_plane.ParseAndAddStatValue(
      *device_plane.GetOrCreateStatMetadata("clock_rate"),
      absl::StrCat(kClockRateKHz));
  device_plane.ParseAndAddStatValue(
      *device_plane.GetOrCreateStatMetadata("core_count"),
      absl::StrCat(kCoreCount));
  device_plane.ParseAndAddStatValue(
      *device_plane.GetOrCreateStatMetadata("memory_bandwidth"),
      absl::StrCat(kMemoryBandwidthBytesPerSecond));
  device_plane.ParseAndAddStatValue(
      *device_plane.GetOrCreateStatMetadata("compute_cap_major"),
      absl::StrCat(kComputeCapMajor));
  device_plane.ParseAndAddStatValue(
      *device_plane.GetOrCreateStatMetadata("compute_cap_minor"),
      absl::StrCat(kComputeCapMinor));

  GroupTfEvents(&space);
  OpStatsOptions options;
  options.generate_op_metrics_db = true;
  OpStats op_stats = ConvertXSpaceToOpStats(space, options);
  const PerfEnv& perf_env = op_stats.perf_env();
  EXPECT_NEAR(141, perf_env.peak_tera_flops_per_second(), kMaxError);
  EXPECT_NEAR(900, perf_env.peak_hbm_bw_giga_bytes_per_second(), kMaxError);
  EXPECT_NEAR(156.67, perf_env.ridge_point(), kMaxError);
}

TEST(ConvertXPlaneToOpStats, RunEnvironment) {
  XSpace space;
  XPlaneBuilder device_plane1(
      GetOrCreateGpuXPlane(&space, /*device_ordinal=*/0));
  XPlaneBuilder device_plane2(
      GetOrCreateGpuXPlane(&space, /*device_ordinal=*/1));

  GroupTfEvents(&space);
  OpStats op_stats = ConvertXSpaceToOpStats(space, OpStatsOptions());
  const RunEnvironment& run_env = op_stats.run_environment();

  EXPECT_EQ("GPU", run_env.device_type());
  EXPECT_EQ(1, run_env.host_count());
  EXPECT_EQ(1, run_env.task_count());
  EXPECT_EQ(2, run_env.device_core_count());
}

TEST(ConvertXPlaneToOpStats, CpuOnlyStepDbTest) {
  constexpr int64 kStepNum = 123;
  constexpr int64 kStepId = 0;

  XSpace space;
  XPlaneBuilder host_plane_builder(GetOrCreateHostXPlane(&space));
  host_plane_builder.ReserveLines(2);

  auto main_thread = host_plane_builder.GetOrCreateLine(0);
  CreateXEvent(&host_plane_builder, &main_thread, HostEventType::kTraceContext,
               0, 100, {{StatType::kStepNum, kStepNum}});
  CreateXEvent(&host_plane_builder, &main_thread, HostEventType::kFunctionRun,
               10, 90, {{StatType::kStepId, kStepId}});

  auto tf_executor_thread = host_plane_builder.GetOrCreateLine(1);
  CreateXEvent(&host_plane_builder, &tf_executor_thread,
               HostEventType::kExecutorStateProcess, 20, 80,
               {{StatType::kStepId, kStepId}});
  CreateXEvent(&host_plane_builder, &tf_executor_thread, "matmul", 30, 70);

  GroupTfEvents(&space);
  OpStatsOptions options;
  options.generate_op_metrics_db = true;
  options.generate_step_db = true;
  OpStats op_stats = ConvertXSpaceToOpStats(space, options);
  const StepDatabaseResult& step_db = op_stats.step_db();

  EXPECT_EQ(step_db.step_sequence_size(), 1);
}

TEST(ConvertXPlaneToOpStats, GpuStepDbTest) {
  constexpr int64 kStepNum = 123;
  constexpr int64 kStepId = 0;
  constexpr int64 kCorrelationId = 100;

  XSpace space;
  XPlaneBuilder host_plane_builder(GetOrCreateHostXPlane(&space));
  host_plane_builder.ReserveLines(2);

  auto main_thread = host_plane_builder.GetOrCreateLine(0);
  CreateXEvent(&host_plane_builder, &main_thread, HostEventType::kTraceContext,
               0, 100, {{StatType::kStepNum, kStepNum}});
  CreateXEvent(&host_plane_builder, &main_thread, HostEventType::kFunctionRun,
               10, 90, {{StatType::kStepId, kStepId}});

  auto tf_executor_thread = host_plane_builder.GetOrCreateLine(1);
  CreateXEvent(&host_plane_builder, &tf_executor_thread,
               HostEventType::kExecutorStateProcess, 20, 20,
               {{StatType::kStepId, kStepId}});
  CreateXEvent(&host_plane_builder, &tf_executor_thread, "matmul", 30, 10,
               {{StatType::kCorrelationId, kCorrelationId}});

  XPlaneBuilder device_plane_builder(
      GetOrCreateGpuXPlane(&space, /*device_ordinal=*/0));
  device_plane_builder.ReserveLines(1);

  auto stream = device_plane_builder.GetOrCreateLine(0);
  CreateXEvent(&device_plane_builder, &stream, "matmul", 50, 40,
               {{StatType::kCorrelationId, kCorrelationId}});

  GroupTfEvents(&space);
  OpStatsOptions options;
  options.generate_op_metrics_db = true;
  options.generate_step_db = true;
  OpStats op_stats = ConvertXSpaceToOpStats(space, options);
  const StepDatabaseResult& step_db = op_stats.step_db();

  EXPECT_EQ(step_db.step_sequence_size(), 1);

  PrecisionStats precision_stats =
      op_stats.device_op_metrics_db().precision_stats();
  EXPECT_EQ(precision_stats.compute_16bit_ps(), 0);
  EXPECT_EQ(precision_stats.compute_32bit_ps(), 40);
}

TEST(ConvertXPlaneToOpStats, PropagateAndDedupErrors) {
  XSpace space;
  static constexpr char kError[] = "host: error";
  *space.add_errors() = kError;
  *space.add_errors() = kError;

  OpStats op_stats = ConvertXSpaceToOpStats(space, OpStatsOptions());

  EXPECT_EQ(1, op_stats.diagnostics().errors_size());
  EXPECT_EQ(kError, op_stats.diagnostics().errors(/*index=*/0));
}

// Helper function to build a XSpace and store it to test directory.
void BuildAndStoreXSpaceForTest(Env* test_env, const std::string& test_dir,
                                const std::string& xspace_name) {
  constexpr int64 kStepNum = 123;
  constexpr int64 kStepId = 456;
  // Create a host only XSpace for test.
  XSpace xspace;
  XPlaneBuilder host_plane_builder(GetOrCreateHostXPlane(&xspace));
  host_plane_builder.ReserveLines(2);

  auto main_thread = host_plane_builder.GetOrCreateLine(0);
  CreateXEvent(&host_plane_builder, &main_thread, HostEventType::kTraceContext,
               0, 100, {{StatType::kStepNum, kStepNum}});
  CreateXEvent(&host_plane_builder, &main_thread, HostEventType::kFunctionRun,
               10, 90, {{StatType::kStepId, kStepId}});

  auto executor_thread = host_plane_builder.GetOrCreateLine(1);
  CreateXEvent(&host_plane_builder, &executor_thread,
               HostEventType::kExecutorStateProcess, 20, 80,
               {{StatType::kStepId, kStepId}});
  // Create a TensorFlow op that runs for 70 ps.
  CreateXEvent(&host_plane_builder, &executor_thread, "aaa:bbb", 30, 70);
  GroupTfEvents(&xspace);

  TF_CHECK_OK(
      WriteBinaryProto(test_env, io::JoinPath(test_dir, xspace_name), xspace))
      << "Failed to write binary XSpace to file: " << xspace_name;
}

TEST(ConvertXPlaneToOpStats, TestConvertMultiXSpacesToCombinedOpStats) {
  // Initialize environment and directory for testing.
  Env* test_env = Env::Default();
  std::string test_dir = io::JoinPath(testing::TmpDir(), "test_dir");
  TF_CHECK_OK(test_env->CreateDir(test_dir))
      << "Failed to create test directory: " << test_dir;

  const std::string xspace1 = "xspace1.pb";
  const std::string xspace2 = "xspace2.pb";
  BuildAndStoreXSpaceForTest(test_env, test_dir, xspace1);
  BuildAndStoreXSpaceForTest(test_env, test_dir, xspace2);

  std::vector<std::string> xspace_paths;
  xspace_paths.push_back(io::JoinPath(test_dir, xspace1));
  xspace_paths.push_back(io::JoinPath(test_dir, xspace2));
  OpStatsOptions options;
  options.generate_op_metrics_db = true;
  options.generate_step_db = true;
  OpStats combined_op_stats;

  TF_CHECK_OK(ConvertMultiXSpacesToCombinedOpStats(xspace_paths, options,
                                                   &combined_op_stats))
      << "Failed to convert multi XSpace to OpStats";

  // Result OpStats has 2 Host Ops, "IDLE" and "aaa:bbb".
  ASSERT_EQ(combined_op_stats.host_op_metrics_db().metrics_db_size(), 2);
  const auto& metric = combined_op_stats.host_op_metrics_db().metrics_db(1);
  EXPECT_EQ(metric.name(), "aaa");
  EXPECT_EQ(metric.category(), "bbb");
  // Each host has the HostOp "aaa:bbb" running for 70 ps, so the combined
  // OpStats has "aaa:bbb" running for 140 ps in total.
  EXPECT_EQ(metric.self_time_ps(), 140);

  // Result OpStats has 1 step, 2 cores.
  ASSERT_EQ(combined_op_stats.step_db().step_sequence_size(), 1);
  ASSERT_EQ(
      combined_op_stats.step_db().step_sequence(0).step_info_per_core_size(),
      2);
  const auto& step_info_per_core =
      combined_op_stats.step_db().step_sequence(0).step_info_per_core();
  // global_core_id is computed using: 1000 * host_id + local_core_id.
  EXPECT_TRUE(step_info_per_core.contains(1));
  EXPECT_TRUE(step_info_per_core.contains(1001));

  // Tear down environment and directory for testing.
  int64 undeleted_files, undeleted_dirs;
  TF_CHECK_OK(
      test_env->DeleteRecursively(test_dir, &undeleted_files, &undeleted_dirs))
      << "Failed to delete test directory: " << test_dir;
}

}  // namespace
}  // namespace profiler
}  // namespace tensorflow
