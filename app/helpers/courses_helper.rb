module CoursesHelper
  STATUS_BADGES = {
    "pending" => { bg: "bg-mustard-light", text: "text-mustard", border: "border-mustard/30", label: "Pending" },
    "validating" => { bg: "bg-sky-light", text: "text-sky", border: "border-sky/30", label: "Validating&hellip;" },
    "approved" => { bg: "bg-sage-light", text: "text-sage", border: "border-sage/30", label: "Approved" },
    "failed" => { bg: "bg-terracotta-light", text: "text-terracotta", border: "border-terracotta/30", label: "Failed" }
  }.freeze

  def status_badge(course)
    badge = STATUS_BADGES[course.status] || return
    tag.span(badge[:label].html_safe, class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium border #{badge[:bg]} #{badge[:text]} #{badge[:border]}")
  end
end
