module ApplicationHelper
  SITE_NAME = "Beerkeeper".freeze

  def page_title(title)
    content_for(:title, title)
  end

  def document_title
    safe_join([ content_for(:title).presence, SITE_NAME ].compact, "｜")
  end
end
