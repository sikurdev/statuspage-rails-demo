module ApplicationHelper
  STATUS_LABELS = {
    "up" => "Operational", "down" => "Outage", "pending" => "Pending",
    operational: "All systems operational", partial_outage: "Partial outage", major_outage: "Major outage"
  }.freeze

  def status_label(status) = STATUS_LABELS.fetch(status.is_a?(Symbol) ? status : status.to_s, status.to_s.humanize)

  def status_badge(status)
    tag.span status_label(status), class: "badge badge--#{status}"
  end

  def format_uptime(percent)
    percent ? "#{format('%.2f', percent)}%" : "—"
  end

  def page_title = ENV.fetch("STATUS_PAGE_TITLE", "Acme Cloud Status")
end
