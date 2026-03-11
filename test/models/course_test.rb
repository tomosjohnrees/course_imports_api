require "test_helper"

class CourseTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(github_id: "course-test-user", github_username: "coursetester")
    @valid_attributes = {
      user: @user,
      github_repo_url: "https://github.com/owner/repo",
      github_owner: "owner",
      github_repo: "repo",
      title: "My Course",
      status: "pending"
    }
  end

  test "valid course with all required attributes" do
    course = Course.new(@valid_attributes)
    assert course.valid?
  end

  test "validates presence of github_repo_url" do
    course = Course.new(@valid_attributes.merge(github_repo_url: nil))
    assert_not course.valid?
    assert_includes course.errors[:github_repo_url], "can't be blank"
  end

  test "validates presence of github_owner" do
    course = Course.new(@valid_attributes.merge(github_owner: nil, github_repo_url: nil))
    assert_not course.valid?
    assert_includes course.errors[:github_owner], "can't be blank"
  end

  test "validates presence of github_repo" do
    course = Course.new(@valid_attributes.merge(github_repo: nil, github_repo_url: nil))
    assert_not course.valid?
    assert_includes course.errors[:github_repo], "can't be blank"
  end

  test "validates presence of title" do
    course = Course.new(@valid_attributes.merge(title: nil, github_repo_url: nil))
    assert_not course.valid?
    assert_includes course.errors[:title], "can't be blank"
  end

  test "validates presence of status" do
    course = Course.new(@valid_attributes.merge(status: nil))
    assert_not course.valid?
    assert_includes course.errors[:status], "can't be blank"
  end

  test "validates status inclusion in STATUSES" do
    course = Course.new(@valid_attributes.merge(status: "invalid_status"))
    assert_not course.valid?
    assert_includes course.errors[:status], "is not included in the list"
  end

  test "accepts all valid statuses" do
    Course.statuses.each_key do |status|
      course = Course.new(@valid_attributes.merge(status: status, github_owner: "owner-#{status}", github_repo: "repo-#{status}"))
      assert course.valid?, "Expected status '#{status}' to be valid, but got errors: #{course.errors.full_messages}"
    end
  end

  test "statuses enum contains expected values" do
    assert_equal %w[pending validating approved failed], Course.statuses.keys
  end

  test "validates github_repo_url format accepts valid GitHub URLs" do
    valid_urls = [
      "https://github.com/owner/repo",
      "https://github.com/my-org/my-repo",
      "https://github.com/user123/project_name",
      "https://github.com/User.Name/Repo.Name"
    ]

    valid_urls.each do |url|
      course = Course.new(@valid_attributes.merge(github_repo_url: url, github_owner: "unique-#{url.hash.abs}", github_repo: "repo-#{url.hash.abs}"))
      assert course.valid?, "Expected '#{url}' to be valid, but got errors: #{course.errors.full_messages}"
    end
  end

  test "validates github_repo_url format rejects non-GitHub URLs" do
    invalid_urls = [
      "https://gitlab.com/owner/repo",
      "http://github.com/owner/repo",
      "https://github.com/owner",
      "https://github.com/",
      "https://github.com/owner/repo/extra",
      "ftp://github.com/owner/repo",
      "not-a-url",
      ""
    ]

    invalid_urls.each do |url|
      course = Course.new(@valid_attributes.merge(github_repo_url: url))
      assert_not course.valid?, "Expected '#{url}' to be invalid"
    end
  end

  test "validates uniqueness of github_owner scoped to github_repo" do
    Course.create!(@valid_attributes)
    duplicate = Course.new(@valid_attributes.merge(title: "Different Title", github_repo_url: "https://github.com/owner/repo"))
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:github_owner], "has already been taken"
  end

  test "allows same github_owner with different github_repo" do
    Course.create!(@valid_attributes)
    different_repo = Course.new(@valid_attributes.merge(github_repo: "different-repo", github_repo_url: "https://github.com/owner/different-repo"))
    assert different_repo.valid?
  end

  test "allows same github_repo with different github_owner" do
    Course.create!(@valid_attributes)
    different_owner = Course.new(@valid_attributes.merge(github_owner: "different-owner", github_repo_url: "https://github.com/different-owner/repo"))
    assert different_owner.valid?
  end

  test "belongs to user" do
    course = Course.new(@valid_attributes)
    assert_equal @user, course.user
  end

  test "has many validation_attempts" do
    course = Course.create!(@valid_attributes)
    attempt1 = ValidationAttempt.create!(course: course, result: "passed")
    attempt2 = ValidationAttempt.create!(course: course, result: "failed")

    assert_equal 2, course.validation_attempts.count
    assert_includes course.validation_attempts, attempt1
    assert_includes course.validation_attempts, attempt2
  end

  test "destroying course destroys associated validation_attempts" do
    course = Course.create!(@valid_attributes)
    ValidationAttempt.create!(course: course, result: "passed")
    ValidationAttempt.create!(course: course, result: "failed")

    assert_difference "ValidationAttempt.count", -2 do
      course.destroy
    end
  end

  test "pending scope returns only pending courses" do
    pending_course = Course.create!(@valid_attributes)
    approved_course = Course.create!(@valid_attributes.merge(
      status: "approved", github_owner: "other", github_repo: "approved-repo",
      github_repo_url: "https://github.com/other/approved-repo"
    ))

    result = Course.pending
    assert_includes result, pending_course
    assert_not_includes result, approved_course
  end

  test "validating scope returns only validating courses" do
    Course.create!(@valid_attributes)
    validating_course = Course.create!(@valid_attributes.merge(
      status: "validating", github_owner: "other", github_repo: "validating-repo",
      github_repo_url: "https://github.com/other/validating-repo"
    ))

    result = Course.validating
    assert_includes result, validating_course
    assert_equal 1, result.count
  end

  test "approved scope returns only approved courses" do
    Course.create!(@valid_attributes)
    approved_course = Course.create!(@valid_attributes.merge(
      status: "approved", github_owner: "other", github_repo: "approved-repo",
      github_repo_url: "https://github.com/other/approved-repo"
    ))

    result = Course.approved
    assert_includes result, approved_course
    assert_equal 1, result.count
  end

  test "failed scope returns only failed courses" do
    Course.create!(@valid_attributes)
    failed_course = Course.create!(@valid_attributes.merge(
      status: "failed", github_owner: "other", github_repo: "failed-repo",
      github_repo_url: "https://github.com/other/failed-repo"
    ))

    result = Course.failed
    assert_includes result, failed_course
    assert_equal 1, result.count
  end

  test "publicly_visible scope returns only approved courses" do
    pending_course = Course.create!(@valid_attributes)
    approved_course = Course.create!(@valid_attributes.merge(
      status: "approved", github_owner: "visible", github_repo: "visible-repo",
      github_repo_url: "https://github.com/visible/visible-repo"
    ))
    failed_course = Course.create!(@valid_attributes.merge(
      status: "failed", github_owner: "hidden", github_repo: "hidden-repo",
      github_repo_url: "https://github.com/hidden/hidden-repo"
    ))

    result = Course.publicly_visible
    assert_includes result, approved_course
    assert_not_includes result, pending_course
    assert_not_includes result, failed_course
  end

  test "pending? returns true for pending status" do
    course = Course.new(status: "pending")
    assert course.pending?
  end

  test "pending? returns false for non-pending status" do
    course = Course.new(status: "approved")
    assert_not course.pending?
  end

  test "validating? returns true for validating status" do
    course = Course.new(status: "validating")
    assert course.validating?
  end

  test "approved? returns true for approved status" do
    course = Course.new(status: "approved")
    assert course.approved?
  end

  test "failed? returns true for failed status" do
    course = Course.new(status: "failed")
    assert course.failed?
  end

  test "status query methods return false for non-matching statuses" do
    course = Course.new(status: "pending")
    assert_not course.validating?
    assert_not course.approved?
    assert_not course.failed?
  end

  test "requires a user association" do
    course = Course.new(@valid_attributes.except(:user))
    assert_not course.valid?
    assert_includes course.errors[:user], "must exist"
  end

  test "search scope returns all records when query is blank" do
    course1 = Course.create!(@valid_attributes.merge(
      title: "Ruby Fundamentals", github_owner: "search-blank1", github_repo: "ruby-fund",
      github_repo_url: "https://github.com/search-blank1/ruby-fund", status: "approved"
    ))
    course2 = Course.create!(@valid_attributes.merge(
      title: "Python Basics", github_owner: "search-blank2", github_repo: "python-basics",
      github_repo_url: "https://github.com/search-blank2/python-basics", status: "approved"
    ))

    result = Course.search(nil)
    assert_includes result, course1
    assert_includes result, course2
  end

  test "search scope returns all records when query is empty string" do
    course = Course.create!(@valid_attributes.merge(
      title: "Ruby Fundamentals", github_owner: "search-empty1", github_repo: "ruby-fund",
      github_repo_url: "https://github.com/search-empty1/ruby-fund", status: "approved"
    ))

    result = Course.search("")
    assert_includes result, course
  end

  test "search scope matches courses by title" do
    matching = Course.create!(@valid_attributes.merge(
      title: "Advanced Ruby Programming", github_owner: "search-title1", github_repo: "adv-ruby",
      github_repo_url: "https://github.com/search-title1/adv-ruby", status: "approved"
    ))
    non_matching = Course.create!(@valid_attributes.merge(
      title: "Python for Beginners", github_owner: "search-title2", github_repo: "python-begin",
      github_repo_url: "https://github.com/search-title2/python-begin", status: "approved"
    ))

    result = Course.search("ruby")
    assert_includes result, matching
    assert_not_includes result, non_matching
  end

  test "search scope matches courses by description" do
    matching = Course.create!(@valid_attributes.merge(
      title: "Web Course", description: "Learn JavaScript and modern frameworks",
      github_owner: "search-desc1", github_repo: "web-course",
      github_repo_url: "https://github.com/search-desc1/web-course", status: "approved"
    ))
    non_matching = Course.create!(@valid_attributes.merge(
      title: "Data Course", description: "Statistics and data analysis",
      github_owner: "search-desc2", github_repo: "data-course",
      github_repo_url: "https://github.com/search-desc2/data-course", status: "approved"
    ))

    result = Course.search("javascript")
    assert_includes result, matching
    assert_not_includes result, non_matching
  end

  test "search scope ranks title matches higher than description matches" do
    title_match = Course.create!(@valid_attributes.merge(
      title: "Kubernetes Deployment Guide", description: "A general course",
      github_owner: "search-rank1", github_repo: "k8s-guide",
      github_repo_url: "https://github.com/search-rank1/k8s-guide", status: "approved"
    ))
    desc_match = Course.create!(@valid_attributes.merge(
      title: "General DevOps", description: "Includes kubernetes container orchestration",
      github_owner: "search-rank2", github_repo: "devops-course",
      github_repo_url: "https://github.com/search-rank2/devops-course", status: "approved"
    ))

    result = Course.search("kubernetes").to_a
    assert_equal title_match, result.first
  end

  test "search scope matches partial words with prefix matching" do
    matching = Course.create!(@valid_attributes.merge(
      title: "Rails Programming Guide", github_owner: "search-partial1", github_repo: "rails-guide",
      github_repo_url: "https://github.com/search-partial1/rails-guide", status: "approved"
    ))
    non_matching = Course.create!(@valid_attributes.merge(
      title: "Python Basics", github_owner: "search-partial2", github_repo: "python-basics",
      github_repo_url: "https://github.com/search-partial2/python-basics", status: "approved"
    ))

    result = Course.search("rail")
    assert_includes result, matching
    assert_not_includes result, non_matching
  end

  test "search scope matches partial words in description" do
    matching = Course.create!(@valid_attributes.merge(
      title: "Web Course", description: "Learn programming fundamentals",
      github_owner: "search-partial-desc1", github_repo: "web-prog",
      github_repo_url: "https://github.com/search-partial-desc1/web-prog", status: "approved"
    ))

    result = Course.search("progr")
    assert_includes result, matching
  end

  test "search scope is case-insensitive" do
    matching = Course.create!(@valid_attributes.merge(
      title: "Python for Data Science", github_owner: "search-case1", github_repo: "python-ds",
      github_repo_url: "https://github.com/search-case1/python-ds", status: "approved"
    ))

    assert_includes Course.search("PYTHON"), matching
    assert_includes Course.search("python"), matching
    assert_includes Course.search("PyThOn"), matching
  end

  test "search scope matches multiple partial words with AND logic" do
    both_terms = Course.create!(@valid_attributes.merge(
      title: "Ruby Programming Guide", github_owner: "search-multi1", github_repo: "ruby-prog-guide",
      github_repo_url: "https://github.com/search-multi1/ruby-prog-guide", status: "approved"
    ))
    one_term = Course.create!(@valid_attributes.merge(
      title: "Ruby Basics", github_owner: "search-multi2", github_repo: "ruby-basics",
      github_repo_url: "https://github.com/search-multi2/ruby-basics", status: "approved"
    ))

    result = Course.search("rub prog")
    assert_includes result, both_terms
    assert_not_includes result, one_term
  end

  test "search scope returns all when query contains only special characters" do
    course = Course.create!(@valid_attributes.merge(
      title: "Any Course", github_owner: "search-special-only1", github_repo: "any-course",
      github_repo_url: "https://github.com/search-special-only1/any-course", status: "approved"
    ))

    result = Course.search("!@#$%")
    assert_includes result, course
  end

  test "search scope handles extra whitespace in query" do
    matching = Course.create!(@valid_attributes.merge(
      title: "Rails Application Development", github_owner: "search-ws1", github_repo: "rails-app",
      github_repo_url: "https://github.com/search-ws1/rails-app", status: "approved"
    ))

    result = Course.search("  rail   ")
    assert_includes result, matching
  end

  test "search scope handles query with mixed valid and special-character-only terms" do
    matching = Course.create!(@valid_attributes.merge(
      title: "Python Machine Learning", github_owner: "search-mixed1", github_repo: "python-ml",
      github_repo_url: "https://github.com/search-mixed1/python-ml", status: "approved"
    ))

    result = Course.search("pyth !!! learn")
    assert_includes result, matching
  end

  test "partial search does not return non-approved courses" do
    approved = Course.create!(@valid_attributes.merge(
      title: "Rails Development", github_owner: "search-vis1", github_repo: "rails-dev",
      github_repo_url: "https://github.com/search-vis1/rails-dev", status: "approved"
    ))
    pending_course = Course.create!(@valid_attributes.merge(
      title: "Rails Beginner", github_owner: "search-vis2", github_repo: "rails-begin",
      github_repo_url: "https://github.com/search-vis2/rails-begin", status: "pending"
    ))
    failed_course = Course.create!(@valid_attributes.merge(
      title: "Rails Advanced", github_owner: "search-vis3", github_repo: "rails-adv",
      github_repo_url: "https://github.com/search-vis3/rails-adv", status: "failed"
    ))

    result = Course.publicly_visible.search("rail")
    assert_includes result, approved
    assert_not_includes result, pending_course
    assert_not_includes result, failed_course
  end

  test "search scope returns empty relation for non-matching query" do
    Course.create!(@valid_attributes.merge(
      title: "Ruby Programming", github_owner: "search-nomatch1", github_repo: "ruby-prog",
      github_repo_url: "https://github.com/search-nomatch1/ruby-prog", status: "approved"
    ))

    result = Course.search("nonexistentxyzterm")
    assert_empty result
  end

  test "search scope chains with publicly_visible" do
    approved_match = Course.create!(@valid_attributes.merge(
      title: "Approved Rails Course", github_owner: "search-chain1", github_repo: "rails-course",
      github_repo_url: "https://github.com/search-chain1/rails-course", status: "approved"
    ))
    pending_match = Course.create!(@valid_attributes.merge(
      title: "Pending Rails Course", github_owner: "search-chain2", github_repo: "rails-pending",
      github_repo_url: "https://github.com/search-chain2/rails-pending", status: "pending"
    ))

    result = Course.publicly_visible.search("rails")
    assert_includes result, approved_match
    assert_not_includes result, pending_match
  end

  test "search scope handles special characters safely" do
    Course.create!(@valid_attributes.merge(
      title: "Normal Course", github_owner: "search-special1", github_repo: "normal-course",
      github_repo_url: "https://github.com/search-special1/normal-course", status: "approved"
    ))

    assert_nothing_raised do
      Course.search("'; DROP TABLE courses; --").to_a
    end
  end

  test "with_tag scope returns courses that include the given tag" do
    tagged = Course.create!(@valid_attributes.merge(
      title: "Ruby Course", github_owner: "tag-scope1", github_repo: "ruby-tagged",
      github_repo_url: "https://github.com/tag-scope1/ruby-tagged", status: "approved",
      tags: [ "ruby", "web" ]
    ))
    untagged = Course.create!(@valid_attributes.merge(
      title: "Python Course", github_owner: "tag-scope2", github_repo: "python-tagged",
      github_repo_url: "https://github.com/tag-scope2/python-tagged", status: "approved",
      tags: [ "python" ]
    ))

    result = Course.with_tag("ruby")
    assert_includes result, tagged
    assert_not_includes result, untagged
  end

  test "with_tag scope returns all courses when tag is blank" do
    course1 = Course.create!(@valid_attributes.merge(
      github_owner: "tag-blank1", github_repo: "repo-blank1",
      github_repo_url: "https://github.com/tag-blank1/repo-blank1", tags: [ "ruby" ]
    ))
    course2 = Course.create!(@valid_attributes.merge(
      github_owner: "tag-blank2", github_repo: "repo-blank2",
      github_repo_url: "https://github.com/tag-blank2/repo-blank2", tags: []
    ))

    result = Course.with_tag(nil)
    assert_includes result, course1
    assert_includes result, course2

    result_empty = Course.with_tag("")
    assert_includes result_empty, course1
    assert_includes result_empty, course2
  end

  test "with_tag scope returns empty when no courses match the tag" do
    Course.create!(@valid_attributes.merge(
      github_owner: "tag-nomatch1", github_repo: "repo-nomatch1",
      github_repo_url: "https://github.com/tag-nomatch1/repo-nomatch1",
      tags: [ "ruby", "rails" ], status: "approved"
    ))

    result = Course.with_tag("nonexistenttag")
    assert_empty result
  end

  test "with_tag scope chains with publicly_visible" do
    approved_tagged = Course.create!(@valid_attributes.merge(
      github_owner: "tag-chain1", github_repo: "repo-chain1",
      github_repo_url: "https://github.com/tag-chain1/repo-chain1",
      tags: [ "ruby" ], status: "approved"
    ))
    pending_tagged = Course.create!(@valid_attributes.merge(
      github_owner: "tag-chain2", github_repo: "repo-chain2",
      github_repo_url: "https://github.com/tag-chain2/repo-chain2",
      tags: [ "ruby" ], status: "pending"
    ))

    result = Course.publicly_visible.with_tag("ruby")
    assert_includes result, approved_tagged
    assert_not_includes result, pending_tagged
  end

  test "with_tag scope chains with search" do
    matching = Course.create!(@valid_attributes.merge(
      title: "Ruby Web Development", github_owner: "tag-search1", github_repo: "ruby-web",
      github_repo_url: "https://github.com/tag-search1/ruby-web",
      tags: [ "ruby" ], status: "approved"
    ))
    wrong_tag = Course.create!(@valid_attributes.merge(
      title: "Python Web Development", github_owner: "tag-search2", github_repo: "python-web",
      github_repo_url: "https://github.com/tag-search2/python-web",
      tags: [ "python" ], status: "approved"
    ))

    result = Course.search("web").with_tag("ruby")
    assert_includes result, matching
    assert_not_includes result, wrong_tag
  end

  test "deep_link_url generates correct protocol URL" do
    course = Course.new(github_owner: "myorg", github_repo: "mycourse")
    assert_equal "courseimports://import/myorg/mycourse", course.deep_link_url
  end

  test "deep_link_url handles hyphenated owner and repo" do
    course = Course.new(github_owner: "my-org", github_repo: "my-cool-course")
    assert_equal "courseimports://import/my-org/my-cool-course", course.deep_link_url
  end

  test "viewable_by? returns true for approved course with nil user" do
    course = Course.new(status: "approved")
    assert course.viewable_by?(nil)
  end

  test "viewable_by? returns true for approved course with any user" do
    course = Course.new(status: "approved")
    assert course.viewable_by?(@user)
  end

  test "viewable_by? returns true for non-approved course owned by user" do
    course = Course.new(@valid_attributes.merge(status: "pending", user: @user))
    assert course.viewable_by?(@user)
  end

  test "viewable_by? returns false for non-approved course with nil user" do
    course = Course.new(status: "pending")
    assert_not course.viewable_by?(nil)
  end

  test "viewable_by? returns false for non-approved course owned by another user" do
    other_user = User.create!(github_id: "viewable-other", github_username: "viewableother")
    course = Course.new(@valid_attributes.merge(status: "pending", user: other_user))
    assert_not course.viewable_by?(@user)
  end
end
