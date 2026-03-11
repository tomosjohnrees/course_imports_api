require "test_helper"
require "zip"

class PagesControllerTest < ActionDispatch::IntegrationTest
  include OmniAuthTestHelper

  setup do
    OmniAuth.config.test_mode = true
    @user = User.create!(
      github_id: "pages-001",
      github_username: "pagesuser",
      avatar_url: "https://example.com/avatar.png",
      github_token: "ghp_pages_token"
    )
  end

  teardown do
    OmniAuth.config.mock_auth[:github] = nil
  end

  # --- Routing ---

  test "routes the authoring guide page" do
    assert_routing({ path: "/authoring-guide", method: :get },
                   { controller: "pages", action: "authoring_guide" })
  end

  test "routes the download skill endpoint" do
    assert_routing({ path: "/authoring-guide/skill", method: :get },
                   { controller: "pages", action: "download_skill" })
  end

  # --- Authoring guide page ---

  test "authoring_guide returns 200 without authentication" do
    get authoring_guide_path
    assert_response :success
  end

  test "authoring_guide returns 200 when signed in" do
    sign_in_as(@user)

    get authoring_guide_path
    assert_response :success
  end

  test "authoring_guide sets page title" do
    get authoring_guide_path
    assert_select "title", text: /Course Authoring Guide/
  end

  test "authoring_guide renders course format specification content" do
    get authoring_guide_path
    assert_select "h1", text: /Course Authoring Guide/
    assert_select "h2", text: /Folder structure/
    assert_select "h2", text: /course\.json/
    assert_select "h2", text: /Block types/
    assert_select "h2", text: /Validation checklist/
  end

  test "authoring_guide renders download skill button" do
    get authoring_guide_path
    assert_select "a[href='#{download_skill_path}']", minimum: 1
  end

  # --- Download skill endpoint ---

  test "download_skill returns a zip file without authentication" do
    get download_skill_path
    assert_response :success
    assert_equal "application/zip", response.content_type
  end

  test "download_skill sets correct filename in content-disposition" do
    get download_skill_path
    assert_match(/creating-course-skill\.zip/, response.headers["Content-Disposition"])
    assert_match(/attachment/, response.headers["Content-Disposition"])
  end

  test "download_skill returns a valid zip containing both skill files" do
    get download_skill_path

    entries = extract_zip_entries(response.body)
    assert_includes entries.keys, "SKILL.md"
    assert_includes entries.keys, "course_authoring_guide.md"
    assert_equal 2, entries.size
  end

  test "download_skill zip contains correct file contents" do
    get download_skill_path

    entries = extract_zip_entries(response.body)
    expected_skill = Rails.root.join("docs/creating-course/SKILL.md").read
    expected_guide = Rails.root.join("docs/creating-course/course_authoring_guide.md").read

    assert_equal expected_skill, entries["SKILL.md"]
    assert_equal expected_guide, entries["course_authoring_guide.md"]
  end

  test "download_skill returns 200 when signed in" do
    sign_in_as(@user)

    get download_skill_path
    assert_response :success
    assert_equal "application/zip", response.content_type
  end

  # --- Navbar integration ---

  test "navbar shows authoring guide link when not signed in" do
    get root_path
    assert_select "nav a[href='#{authoring_guide_path}']", text: "Authoring Guide"
  end

  test "navbar shows authoring guide link when signed in" do
    sign_in_as(@user)

    get root_path
    assert_select "nav a[href='#{authoring_guide_path}']", text: "Authoring Guide"
  end

  # --- Security: no path traversal ---

  test "download_skill only serves the hardcoded skill files" do
    get download_skill_path

    entries = extract_zip_entries(response.body)
    entries.each_key do |name|
      assert_includes PagesController::SKILL_FILES, name,
        "Unexpected file in zip: #{name}"
    end
  end

  test "download_skill does not accept user parameters to alter files" do
    get download_skill_path, params: { file: "../../config/credentials.yml.enc" }
    assert_response :success

    entries = extract_zip_entries(response.body)
    assert_equal 2, entries.size
    refute entries.keys.any? { |k| k.include?("credentials") }
  end

  private

  def extract_zip_entries(zip_data)
    entries = {}
    io = StringIO.new(zip_data)
    Zip::InputStream.open(io) do |zip|
      while (entry = zip.get_next_entry)
        entries[entry.name] = zip.read.force_encoding("UTF-8")
      end
    end
    entries
  end
end
