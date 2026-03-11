class User < ApplicationRecord
  encrypts :github_token

  has_many :courses, dependent: :destroy
  has_many :course_favourites, dependent: :delete_all
  has_many :favourited_courses, through: :course_favourites, source: :course

  validates :github_id, presence: true, uniqueness: true
  validates :github_username, presence: true

  scope :banned, -> { where(banned: true) }

  self.filter_attributes += [ :github_token ]

  def favourited_course?(course)
    course_favourites.exists?(course: course)
  end

  def favourited_course_ids_among(courses)
    course_favourites.where(course_id: courses.map(&:id)).pluck(:course_id).to_set
  end

  def self.find_or_create_from_omniauth(auth_hash)
    user = find_or_initialize_by(github_id: auth_hash["uid"].to_s)
    user.update!(
      github_username: auth_hash.dig("info", "nickname"),
      display_name: auth_hash.dig("info", "name"),
      avatar_url: auth_hash.dig("info", "image"),
      github_token: auth_hash.dig("credentials", "token")
    )
    user
  end
end
