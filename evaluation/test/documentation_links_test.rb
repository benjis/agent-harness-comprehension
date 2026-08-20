# frozen_string_literal: true

require "minitest/autorun"
require "uri"

class DocumentationLinksTest < Minitest::Test
  REPOSITORY_ROOT = File.expand_path("../..", __dir__)
  MARKDOWN_LINK = /\[[^\]]*\]\(([^)]+)\)/

  def test_repository_markdown_has_no_broken_relative_file_links
    failures = markdown_files.flat_map do |document|
      File.read(document).scan(MARKDOWN_LINK).filter_map do |match|
        destination = match.fetch(0).split("#", 2).first
        next if destination.empty? || external?(destination)

        resolved = File.expand_path(URI::DEFAULT_PARSER.unescape(destination), File.dirname(document))
        next if File.exist?(resolved)

        "#{document.delete_prefix(REPOSITORY_ROOT + File::SEPARATOR)} -> #{destination}"
      end
    end

    assert_empty failures, "broken Markdown links:\n#{failures.join("\n")}"
  end

  private

  def markdown_files
    Dir[File.join(REPOSITORY_ROOT, "**", "*.md")].reject do |path|
      path.include?("/node_modules/") || path.include?("/.git/")
    end
  end

  def external?(destination)
    destination.start_with?("#", "/") || destination.match?(/\A[a-z][a-z0-9+.-]*:/i)
  end
end
