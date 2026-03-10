require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  include OmniAuthTestHelper

  setup do
    OmniAuth.config.test_mode = true
  end

  teardown do
    OmniAuth.config.mock_auth[:github] = nil
  end

  test "home page responds successfully" do
    get root_path
    assert_response :success
  end

  test "home page displays app title" do
    get root_path
    assert_select "h1", "Course Imports"
  end

  test "home page shows sign-in button when not signed in" do
    get root_path
    assert_select "form[action='/auth/github']" do
      assert_select "button", text: /Sign in with GitHub/
    end
  end

  test "home page hides sign-in call-to-action when signed in" do
    user = User.create!(github_id: "70001", github_username: "homeuser", avatar_url: "https://example.com/avatar.png")
    sign_in_as(user)
    follow_redirect!

    get root_path
    assert_select ".max-w-2xl form[action='/auth/github']", count: 0
  end

  test "root route maps to pages#home" do
    assert_routing({ path: "/", method: :get },
                   { controller: "pages", action: "home" })
  end
end
