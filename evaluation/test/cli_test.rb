# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "tmpdir"

class CliTest < Minitest::Test
  def test_prepare_command_creates_a_clean_task_workspace
    Dir.mktmpdir("comprehension-cli-") do |directory|
      workspace = File.join(directory, "workspace")
      cli = File.expand_path("../bin/study", __dir__)
      output, error, status = Open3.capture3(cli, "prepare", "medium-atomic-reservation", workspace)

      assert status.success?, error
      assert_includes output, "medium-atomic-reservation"
      assert File.file?(File.join(workspace, "lib", "parcel_flow", "inventory.rb"))
    end
  end
end
