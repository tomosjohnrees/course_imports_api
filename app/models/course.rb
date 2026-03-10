class Course < ApplicationRecord
  GITHUB_REPO_URL_PATTERN = %r{\Ahttps://github\.com/[a-zA-Z0-9\-_.]+/[a-zA-Z0-9\-_.]+\z}

  enum :status, { pending: "pending", validating: "validating", approved: "approved", failed: "failed", removed: "removed" }, validate: true

  scope :publicly_visible, -> { approved }

  belongs_to :user
  has_many :validation_attempts, dependent: :destroy

  validates :github_repo_url, presence: true, format: { with: GITHUB_REPO_URL_PATTERN }
  validates :github_owner, presence: true
  validates :github_repo, presence: true
  validates :title, presence: true
  validates :status, presence: true
  validates :github_owner, uniqueness: { scope: :github_repo }
end
