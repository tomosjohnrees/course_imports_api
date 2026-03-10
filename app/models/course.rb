class Course < ApplicationRecord
  include Course::Validatable

  GITHUB_REPO_URL_PATTERN = %r{\Ahttps://github\.com/(?<owner>[a-zA-Z0-9\-_.]+)/(?<repo>[a-zA-Z0-9\-_.]+)\z}

  enum :status, { pending: "pending", validating: "validating", approved: "approved", failed: "failed", removed: "removed" }, validate: true

  scope :publicly_visible, -> { approved }
  scope :search, ->(query) {
    return all if query.blank?

    where("search_vector @@ websearch_to_tsquery('english', ?)", query)
      .order(Arel.sql(sanitize_sql_array([ "ts_rank(search_vector, websearch_to_tsquery('english', ?)) DESC", query ])))
  }
  scope :with_tag, ->(tag) {
    return all if tag.blank?

    where("tags @> ARRAY[?]::varchar[]", tag)
  }

  def self.unique_tags
    publicly_visible.where("array_length(tags, 1) > 0").pluck(Arel.sql("DISTINCT unnest(tags)")).sort
  end

  belongs_to :user
  has_many :validation_attempts, dependent: :destroy

  before_validation :extract_github_details, if: -> { github_repo_url_changed? }

  validates :github_repo_url, presence: true, format: { with: GITHUB_REPO_URL_PATTERN }
  validates :github_owner, presence: true
  validates :github_repo, presence: true
  validates :title, presence: true
  validates :status, presence: true
  validates :github_owner, uniqueness: { scope: :github_repo }

  def remove!
    update!(status: :removed)
  end

  private

  def extract_github_details
    match = github_repo_url.to_s.strip.match(GITHUB_REPO_URL_PATTERN)
    return unless match

    self.github_repo_url = github_repo_url.strip
    self.github_owner = match[:owner]
    self.github_repo = match[:repo]
    self.title = match[:repo].titleize if title.blank?
  end
end
