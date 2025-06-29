module MarkdownHelper
  def markdown(text, target: nil)
    markdown_object(target: target).render(text.to_s).html_safe
  end

  def markdown_object(target: "_parent")
    render_options = {
      hard_wrap: true,
      link_attributes: {
        target: target
      }
    }
    extensions = {
      autolink: true,
      no_intra_emphasis: true,
      tables: true,
      fenced_code_blocks: true,
      strikethrough: true
    }
    Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(render_options), extensions)
  end
end
