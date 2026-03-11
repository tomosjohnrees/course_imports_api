class PagesController < ApplicationController
  SKILL_FILES = %w[SKILL.md course_authoring_guide.md].freeze

  def privacy
  end

  def terms
  end

  def authoring_guide
  end

  def download_skill
    send_file Rails.root.join("public/downloads/creating-course-skill.zip"),
              filename: "creating-course-skill.zip",
              type: "application/zip",
              disposition: "attachment"
  end
end
