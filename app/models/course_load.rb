class CourseLoad < ApplicationRecord
  belongs_to :course

  validates :identifier, presence: true, uniqueness: { scope: :course_id }
end
