module CoursesHelper
  STATUS_BADGES = {
    "pending" => { bg: "bg-yellow-100", text: "text-yellow-800", label: "Pending" },
    "validating" => { bg: "bg-blue-100", text: "text-blue-800", label: "Validating&hellip;" },
    "approved" => { bg: "bg-green-100", text: "text-green-800", label: "Approved" },
    "failed" => { bg: "bg-red-100", text: "text-red-800", label: "Failed" },
    "removed" => { bg: "bg-gray-100", text: "text-gray-800", label: "Removed" }
  }.freeze

  def status_badge(course)
    badge = STATUS_BADGES[course.status] || return
    tag.span(badge[:label].html_safe, class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{badge[:bg]} #{badge[:text]}")
  end
end
