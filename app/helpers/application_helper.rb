module ApplicationHelper
  def site_owner
    @site_owner ||= User.first
  end

  def site_name
    site_owner&.display_name_or_username || "Pterodon"
  end

  def default_og_image_url
    if site_owner&.avatar&.attached?
      url_for(site_owner.avatar)
    end
  end
end
